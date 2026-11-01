import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_codec_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_decoder_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_frame.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_import_report.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/import_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/select_from_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/binary_exchange_frame_codec_gateway.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Version du protocole de session, annoncée dans [ExchangeFrameType.hello].
///
/// À incrémenter à chaque changement incompatible du déroulé ou des trames. Elle est distincte de la version du
/// format des messages, portée par le codec.
const int exchangeProtocolVersion = 1;

/// Taille maximale d'un envoi au transport, en octets.
///
/// Un lot est découpé pour que chaque morceau accepté prouve que l'échange avance : sans cela, un long envoi
/// ressemblerait à un silence du pair.
const int exchangeChunkBytes = 4 * 1024;

/// Durée sans aucun progrès, ni reçu ni envoyé, au bout de laquelle le pair est considéré comme perdu.
const Duration defaultExchangeInactivityTimeout = Duration(seconds: 15);

/// Durée maximale d'une session, quoi qu'il arrive.
///
/// Empêche un pair d'occuper la radio en envoyant juste assez d'octets pour ne jamais être inactif. Un lot honnête
/// passe en quelques secondes à 30 Ko/s ; cette durée couvre le maximum autorisé dans les deux sens.
const Duration defaultExchangeSessionTimeout = Duration(seconds: 90);

/// Temps accordé à l'envoi de la trame d'abandon et à la fermeture du transport.
///
/// Une session qui se termine ne doit jamais rester bloquée sur une connexion déjà morte.
const Duration _closingTimeout = Duration(seconds: 2);

/// Provider d'une [ExchangeSession] sur un transport donné.
final exchangeSessionProvider = Provider.autoDispose.family<ExchangeSession, ExchangeTransportGateway>((
  ref,
  transport,
) {
  return ExchangeSession(
    transport,
    ref.read(exchangeFrameCodecGatewayProvider),
    ref.read(buildExchangeOfferUsecaseProvider),
    ref.read(selectFromExchangeOfferUsecaseProvider),
    ref.read(buildExchangeBundleUsecaseProvider),
    ref.read(importExchangeBundleUsecaseProvider),
  );
});

/// Déroule un échange complet avec un pair, sur un transport déjà connecté.
///
/// La session relie deux features : `exchange` pour la connexion et les trames, `content` pour ce qui s'échange.
/// C'est pour cela qu'elle vit dans `application`, seule couche qui voit les deux et qui appelle les use cases.
///
/// Les deux appareils jouent exactement le même rôle : il n'y a ni client ni serveur, chacun propose et chacun
/// choisit, en même temps. Une session est à usage unique : elle prend possession du transport et le ferme à la fin.
///
/// ```text
/// Appareil A                         Appareil B
///   HELLO  ───────────────────────────►
///          ◄─────────────────────────── HELLO
///   OFFER  ───────────────────────────►
///          ◄─────────────────────────── OFFER
///   REQUEST ──────────────────────────►
///          ◄─────────────────────────── REQUEST
///   DATA   ───────────────────────────►
///          ◄─────────────────────────── DATA
///   DONE   ───────────────────────────►
///          ◄─────────────────────────── DONE
/// ```
///
/// Chaque trame reçue est traitée jusqu'au bout avant la suivante, y compris l'envoi de la réponse. Conséquence : la
/// réponse à une trame part toujours après la réponse à la précédente, et chaque sens du flux suit strictement l'ordre
/// HELLO, OFFER, REQUEST, DATA, DONE. La session n'attend donc qu'un seul type de trame à la fois, et tout le reste
/// est une violation du protocole. Ce traitement en série garantit aussi qu'un seul use case touche Hive à la fois.
///
/// La lecture du transport, elle, ne s'arrête jamais : les trames sont mises en file pendant que la session envoie.
/// C'est ce qui permet aux deux lots de se croiser sans que chacun attende que l'autre ait fini.
///
/// Le lot voyage d'un bloc : une connexion perdue pendant son transfert ne laisse aucun contenu partiel. L'import a
/// lieu à la réception complète ; une fois fait, l'échange est un succès même si l'accusé du pair n'arrive jamais.
class ExchangeSession {
  /// Crée une [ExchangeSession].
  ///
  /// - [_transport] : connexion avec le pair.
  /// - [_exchangeFrameCodecGateway] : met les trames en octets.
  /// - [_buildExchangeOfferUsecase] : construit l'offre de l'appareil.
  /// - [_selectFromExchangeOfferUsecase] : choisit dans l'offre du pair.
  /// - [_buildExchangeBundleUsecase] : répond à la demande du pair.
  /// - [_importExchangeBundleUsecase] : importe le lot du pair.
  /// - [inactivityTimeout] : durée sans progrès au bout de laquelle le pair est considéré comme perdu.
  /// - [sessionTimeout] : durée maximale de la session.
  ExchangeSession(
    this._transport,
    this._exchangeFrameCodecGateway,
    this._buildExchangeOfferUsecase,
    this._selectFromExchangeOfferUsecase,
    this._buildExchangeBundleUsecase,
    this._importExchangeBundleUsecase, {
    this.inactivityTimeout = defaultExchangeInactivityTimeout,
    this.sessionTimeout = defaultExchangeSessionTimeout,
  });

  /// Durée sans progrès au bout de laquelle le pair est considéré comme perdu.
  final Duration inactivityTimeout;

  /// Durée maximale de la session.
  final Duration sessionTimeout;

  /// Connexion avec le pair.
  final ExchangeTransportGateway _transport;

  /// Met les trames en octets.
  final ExchangeFrameCodecGateway _exchangeFrameCodecGateway;

  /// Construit l'offre de l'appareil.
  final BuildExchangeOfferUsecase _buildExchangeOfferUsecase;

  /// Choisit dans l'offre du pair.
  final SelectFromExchangeOfferUsecase _selectFromExchangeOfferUsecase;

  /// Répond à la demande du pair.
  final BuildExchangeBundleUsecase _buildExchangeBundleUsecase;

  /// Importe le lot du pair.
  final ImportExchangeBundleUsecase _importExchangeBundleUsecase;

  /// Reconstitue les trames du pair.
  late final ExchangeFrameDecoderGateway _decoder = _exchangeFrameCodecGateway.createDecoder();

  /// Résultat de la session, complété une fois le transport fermé.
  final Completer<ExchangeSessionResult> _result = Completer();

  /// Abonnement aux octets du pair.
  StreamSubscription<Uint8List>? _subscription;

  /// Minuteur d'inactivité, relancé à chaque progrès.
  Timer? _inactivityTimer;

  /// Minuteur de durée totale.
  Timer? _sessionTimer;

  /// Fin de la dernière étape en file : les étapes s'exécutent l'une après l'autre.
  Future<void> _lastStep = Future.value();

  /// Seule trame acceptée à cet instant.
  ExchangeFrameType _expectedFrame = ExchangeFrameType.hello;

  /// Demande envoyée au pair : seule liste blanche de ce qu'on accepte de son lot.
  Uint8List? _sentRequest;

  /// Bilan de l'import, `null` tant que le lot du pair n'a pas été traité.
  ExchangeImportReport? _report;

  /// Octets envoyés au pair.
  int _sentBytes = 0;

  /// Octets reçus du pair.
  int _receivedBytes = 0;

  /// Vrai quand une trame est en train de partir : une autre trame s'y mêlerait.
  bool _isSending = false;

  /// Vrai dès que la session se termine, avant même la fermeture du transport.
  bool _isFinished = false;

  /// Déroule l'échange et retourne son résultat, une fois le transport fermé. Ne lève jamais d'exception.
  Future<ExchangeSessionResult> run() {
    _sessionTimer = Timer(sessionTimeout, () => unawaited(_finish(ExchangeSessionFailure.timeout)));
    _restartInactivityTimer();
    _subscription = _transport.incoming.listen(
      _onBytes,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('ExchangeSession', error, stackTrace);
        _enqueue(() => _finish(ExchangeSessionFailure.transportClosed));
      },
      // En file : une fermeture juste après une trame ne doit pas passer avant le traitement de cette trame.
      onDone: () => _enqueue(() => _finish(ExchangeSessionFailure.transportClosed)),
    );
    _enqueue(() => _sendFrame(ExchangeFrameType.hello, Uint8List.fromList([exchangeProtocolVersion])));
    return _result.future;
  }

  /// Interrompt l'échange à la demande de l'utilisateur, et se termine une fois le transport fermé.
  ///
  /// L'arrêt du service doit être immédiat : on n'attend ni la fin de l'envoi en cours, ni l'accord du pair.
  Future<void> cancel() async {
    await _finish(ExchangeSessionFailure.cancelled);
  }

  /// Traite un morceau reçu du transport : il prouve que le pair est vivant, et complète peut-être des trames.
  ///
  /// - [bytes] : morceau reçu.
  void _onBytes(Uint8List bytes) {
    _receivedBytes += bytes.length;
    _restartInactivityTimer();
    final List<ExchangeFrame> frames;
    try {
      frames = _decoder.add(bytes);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('ExchangeSession', error, stackTrace);
      unawaited(_finish(ExchangeSessionFailure.protocolViolation));
      return;
    }
    for (final frame in frames) {
      _enqueue(() => _handleFrame(frame));
    }
  }

  /// Ajoute [step] à la file des étapes.
  ///
  /// - [step] : étape à exécuter après les précédentes.
  void _enqueue(Future<void> Function() step) {
    _lastStep = _runAfter(_lastStep, step);
  }

  /// Exécute [step] une fois [previous] terminée, sauf si la session s'est terminée entre-temps.
  ///
  /// Les use cases ne lèvent pas d'exception : seul le transport le peut, quand la connexion tombe pendant un envoi.
  ///
  /// - [previous] : étape précédente.
  /// - [step] : étape à exécuter.
  Future<void> _runAfter(Future<void> previous, Future<void> Function() step) async {
    await previous;
    if (_isFinished) {
      return;
    }
    try {
      await step();
    } catch (error, stackTrace) {
      AppLogger.error('ExchangeSession', error, stackTrace);
      await _finish(ExchangeSessionFailure.transportClosed);
    }
  }

  /// Vérifie que [frame] est celle attendue, et la traite.
  ///
  /// - [frame] : trame reçue du pair.
  Future<void> _handleFrame(ExchangeFrame frame) async {
    if (frame.type == ExchangeFrameType.error) {
      await _finish(ExchangeSessionFailure.peerError);
      return;
    }
    if (frame.type != _expectedFrame) {
      await _finish(ExchangeSessionFailure.protocolViolation);
      return;
    }

    switch (frame.type) {
      case ExchangeFrameType.hello:
        await _onHello(frame.payload);
      case ExchangeFrameType.offer:
        await _onOffer(frame.payload);
      case ExchangeFrameType.request:
        await _onRequest(frame.payload);
      case ExchangeFrameType.data:
        await _onData(frame.payload);
      case ExchangeFrameType.done:
      case ExchangeFrameType.error:
        await _finish(null);
    }
  }

  /// Vérifie la version du pair, puis lui envoie l'offre.
  ///
  /// L'offre n'est construite qu'à ce moment : inutile de lire la base pour un pair incompatible.
  ///
  /// - [payload] : charge utile du HELLO.
  Future<void> _onHello(Uint8List payload) async {
    if (payload.isEmpty || payload.first != exchangeProtocolVersion) {
      await _finish(ExchangeSessionFailure.incompatibleVersion);
      return;
    }
    final result = await _buildExchangeOfferUsecase(const NoParams());
    final offer = result.right;
    if (offer == null) {
      await _finish(ExchangeSessionFailure.localError);
      return;
    }
    _expectedFrame = ExchangeFrameType.offer;
    await _sendFrame(ExchangeFrameType.offer, offer);
  }

  /// Choisit dans l'offre du pair et lui envoie la demande.
  ///
  /// - [payload] : offre du pair, encodée.
  Future<void> _onOffer(Uint8List payload) async {
    final result = await _selectFromExchangeOfferUsecase(SelectFromExchangeOfferParams(offerBytes: payload));
    final request = result.right;
    if (request == null) {
      final isPeerFault = result.left == SelectFromExchangeOfferFailure.invalidOffer;
      await _finish(isPeerFault ? ExchangeSessionFailure.protocolViolation : ExchangeSessionFailure.localError);
      return;
    }
    _sentRequest = request;
    _expectedFrame = ExchangeFrameType.request;
    await _sendFrame(ExchangeFrameType.request, request);
  }

  /// Construit le lot demandé par le pair et le lui envoie.
  ///
  /// - [payload] : demande du pair, encodée.
  Future<void> _onRequest(Uint8List payload) async {
    final result = await _buildExchangeBundleUsecase(BuildExchangeBundleParams(requestBytes: payload));
    final bundle = result.right;
    if (bundle == null) {
      final isPeerFault = result.left == BuildExchangeBundleFailure.invalidRequest;
      await _finish(isPeerFault ? ExchangeSessionFailure.protocolViolation : ExchangeSessionFailure.localError);
      return;
    }
    _expectedFrame = ExchangeFrameType.data;
    await _sendFrame(ExchangeFrameType.data, bundle);
  }

  /// Importe le lot du pair et lui envoie l'accusé.
  ///
  /// - [payload] : lot du pair, encodé.
  Future<void> _onData(Uint8List payload) async {
    final result = await _importExchangeBundleUsecase(
      ImportExchangeBundleParams(requestBytes: _sentRequest!, bundleBytes: payload),
    );
    final report = result.right;
    if (report == null) {
      final isPeerFault = result.left == ImportExchangeBundleFailure.invalidBundle;
      await _finish(isPeerFault ? ExchangeSessionFailure.protocolViolation : ExchangeSessionFailure.localError);
      return;
    }
    _report = report;
    await _transport.confirmSuccess();
    _expectedFrame = ExchangeFrameType.done;
    await _sendFrame(ExchangeFrameType.done, Uint8List(0));
  }

  /// Envoie une trame au pair, par morceaux.
  ///
  /// Une charge utile plus grande que ce que le pair accepte serait refusée à la réception : autant ne pas occuper
  /// la radio pour rien. Cela arrive si un pair demande bien plus que son budget, ou sur un lot aux réactions
  /// exceptionnellement nombreuses.
  ///
  /// - [type] : type de la trame.
  /// - [payload] : charge utile.
  Future<void> _sendFrame(ExchangeFrameType type, Uint8List payload) async {
    if (payload.length > type.maxPayloadBytes) {
      await _finish(ExchangeSessionFailure.localError);
      return;
    }
    final bytes = _exchangeFrameCodecGateway.encode(ExchangeFrame(type, payload));
    _isSending = true;
    for (var offset = 0; offset < bytes.length && !_isFinished; offset += exchangeChunkBytes) {
      final chunk = Uint8List.sublistView(bytes, offset, min(offset + exchangeChunkBytes, bytes.length));
      await _transport.send(chunk);
      _sentBytes += chunk.length;
      _restartInactivityTimer();
    }
    _isSending = false;
  }

  /// Relance le minuteur d'inactivité : l'échange vient de progresser.
  void _restartInactivityTimer() {
    if (_isFinished) {
      return;
    }
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () => unawaited(_finish(ExchangeSessionFailure.timeout)));
  }

  /// Termine la session : prévient le pair si besoin, ferme le transport et publie le résultat.
  ///
  /// Une fois le lot du pair importé, tout ce que cet échange pouvait apporter à l'appareil est acquis : une
  /// connexion perdue ou un silence en attendant l'accusé n'est plus un échec. C'est même la fin normale quand le
  /// pair ferme la connexion juste après son propre accusé.
  ///
  /// - [failure] : cause de l'échec, `null` si l'échange a réussi.
  Future<void> _finish(ExchangeSessionFailure? failure) async {
    if (_isFinished) {
      return;
    }
    _isFinished = true;
    _inactivityTimer?.cancel();
    _sessionTimer?.cancel();

    final isPeerNotified =
        failure == ExchangeSessionFailure.protocolViolation ||
        failure == ExchangeSessionFailure.localError ||
        failure == ExchangeSessionFailure.cancelled;
    try {
      // Pendant un envoi, la trame d'abandon se mêlerait aux morceaux : la fermeture suffit à prévenir le pair.
      if (isPeerNotified && !_isSending) {
        final abort = ExchangeFrame(ExchangeFrameType.error, Uint8List(0));
        await _transport.send(_exchangeFrameCodecGateway.encode(abort)).timeout(_closingTimeout);
      }
    } catch (error, stackTrace) {
      AppLogger.error('ExchangeSession', error, stackTrace);
    }
    try {
      await _subscription?.cancel().timeout(_closingTimeout);
      await _transport.close().timeout(_closingTimeout);
    } catch (error, stackTrace) {
      AppLogger.error('ExchangeSession', error, stackTrace);
    }

    final isConnectionLoss =
        failure == ExchangeSessionFailure.transportClosed || failure == ExchangeSessionFailure.timeout;
    final report = _report;
    _result.complete(
      ExchangeSessionResult(
        failure: report != null && isConnectionLoss ? null : failure,
        report: report,
        awaitedFrame: _expectedFrame,
        sentBytes: _sentBytes,
        receivedBytes: _receivedBytes,
      ),
    );
  }
}

/// Causes d'échec d'une [ExchangeSession].
enum ExchangeSessionFailure {
  /// Le pair parle une autre version du protocole.
  incompatibleVersion,

  /// Le pair a envoyé des octets incohérents : trame inconnue, hors séquence, trop grande, ou message illisible.
  protocolViolation,

  /// L'appareil n'a pas pu lire sa base ou écrire ce qu'il a reçu.
  localError,

  /// Le pair a abandonné l'échange.
  peerError,

  /// La connexion a été perdue.
  transportClosed,

  /// Le pair ne répond plus, ou l'échange a dépassé sa durée maximale.
  timeout,

  /// L'utilisateur a interrompu l'échange.
  cancelled,
}

/// Résultat d'une [ExchangeSession].
class ExchangeSessionResult {
  /// Crée un [ExchangeSessionResult].
  ///
  /// - [failure] : cause de l'échec, `null` si l'échange a réussi.
  /// - [report] : bilan de l'import, `null` si le lot du pair n'a pas été traité.
  /// - [awaitedFrame] : trame attendue à la fin de la session.
  /// - [sentBytes] : octets envoyés au pair.
  /// - [receivedBytes] : octets reçus du pair.
  const ExchangeSessionResult({
    required this.failure,
    required this.report,
    required this.awaitedFrame,
    required this.sentBytes,
    required this.receivedBytes,
  });

  /// Cause de l'échec, `null` si l'échange a réussi.
  final ExchangeSessionFailure? failure;

  /// Bilan de l'import, `null` si le lot du pair n'a pas été traité.
  ///
  /// Peut être renseigné malgré un échec : ce qui a été importé avant l'abandon du pair reste acquis.
  final ExchangeImportReport? report;

  /// Trame attendue à la fin de la session, qui indique où elle s'est arrêtée.
  final ExchangeFrameType awaitedFrame;

  /// Octets envoyés au pair.
  final int sentBytes;

  /// Octets reçus du pair.
  final int receivedBytes;

  /// Indique si l'échange a réussi.
  bool get isSuccess {
    return failure == null;
  }
}
