import 'dart:async';

import 'package:bedbug/application/exchange/exchange_session.dart';
import 'package:bedbug/application/exchange/exchange_stats_notifier.dart';
import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/screens/exchange_logs/exchange_logs_notifier.dart';
import 'package:bedbug/application/screens/settings/user_settings_notifier.dart';
import 'package:bedbug/features/content/domain/usecases/delete_untrusted_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/enforce_storage_limit_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_broadcast_scores_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_display_scores_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_survival_scores_usecase.dart';
import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_log_outcome.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/peer_attempt.dart';
import 'package:bedbug/features/exchange/domain/usecases/save_exchange_log_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/start_peer_link_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/stop_peer_link_usecase.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_peer_link_gateway.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [PassiveExchangeNotifier].
///
/// Sans `autoDispose` : les échanges continuent quand la page d'échange se ferme. Il est lu dès `main`, avant tout
/// écran : quand Android relance le service en arrière-plan, aucun écran ne le ferait.
final passiveExchangeNotifierProvider = AsyncNotifierProvider<PassiveExchangeNotifier, bool>(
  PassiveExchangeNotifier.new,
);

/// Notifier du transfert passif : son état indique s'il est actif, et il déroule une session par connexion reçue.
///
/// Il vit dans `application` parce qu'il relie la recherche de pairs à [ExchangeSession], qui appelle les use cases.
/// Le choix de l'utilisateur est enregistré : l'échange reprend tout seul au lancement suivant de l'app.
class PassiveExchangeNotifier extends AsyncNotifier<bool> {
  /// Cas d'usage de démarrage de la recherche de pairs.
  late final _startPeerLinkUsecase = ref.read(startPeerLinkUsecaseProvider);

  /// Cas d'usage d'arrêt de la recherche de pairs.
  late final _stopPeerLinkUsecase = ref.read(stopPeerLinkUsecaseProvider);

  /// Cas d'usage de lecture des réglages.
  late final _getSettingsUsecase = ref.read(getSettingsUsecaseProvider);

  /// Cas d'usage d'enregistrement des réglages.
  late final _saveSettingsUsecase = ref.read(saveSettingsUsecaseProvider);

  /// Cas d'usage de recalcul de la priorité de diffusion.
  late final _recalculateBroadcastScoresUsecase = ref.read(recalculateBroadcastScoresUsecaseProvider);

  /// Cas d'usage de recalcul de la priorité d'affichage.
  late final _recalculateDisplayScoresUsecase = ref.read(recalculateDisplayScoresUsecaseProvider);

  /// Cas d'usage de recalcul de la priorité de conservation.
  late final _recalculateSurvivalScoresUsecase = ref.read(recalculateSurvivalScoresUsecaseProvider);

  /// Cas d'usage de nettoyage du stockage.
  late final _enforceStorageLimitUsecase = ref.read(enforceStorageLimitUsecaseProvider);

  /// Cas d'usage de suppression des contenus de domaines absents des listes.
  late final _deleteUntrustedContentsUsecase = ref.read(deleteUntrustedContentsUsecaseProvider);

  /// Cas d'usage d'ajout au journal des échanges.
  late final _saveExchangeLogUsecase = ref.read(saveExchangeLogUsecaseProvider);

  /// Recherche de pairs, dont sont écoutés les connexions et les arrêts.
  late final _peerLinkGateway = ref.read(peerLinkGatewayProvider);

  /// Session en cours, `null` entre deux rencontres.
  ExchangeSession? _session;

  @override
  Future<bool> build() async {
    final connections = _peerLinkGateway.connections.listen((transport) => unawaited(_runSession(transport)));
    final attempts = _peerLinkGateway.attempts.listen((attempt) => unawaited(_logAttempt(attempt)));
    final stopped = _peerLinkGateway.stopped.listen((_) => unawaited(_onStopped()));
    ref.onDispose(() {
      unawaited(connections.cancel());
      unawaited(attempts.cancel());
      unawaited(stopped.cancel());
    });

    final settings = await _getSettingsUsecase(const NoParams());
    if (settings.right?.isExchangeEnabled != true) {
      return false;
    }
    // Sans demande de permissions : au démarrage, il n'y a peut-être aucun écran pour l'afficher.
    final result = await _startPeerLinkUsecase(const StartPeerLinkParams(isPermissionRequested: false));
    return result.isSuccess;
  }

  /// Active ou coupe le transfert passif, et retourne `null` en cas de succès, ou le message d'erreur à afficher.
  ///
  /// À la coupure, la session en cours est annulée d'abord : le pair en est ainsi prévenu.
  ///
  /// - [isEnabled] : `true` pour activer le transfert passif.
  Future<String?> setEnabled({required bool isEnabled}) async {
    state = const AsyncLoading();
    if (!isEnabled) {
      await _session?.cancel();
      await _stopPeerLinkUsecase(const NoParams());
      await _saveChoice(isEnabled: false);
      state = const AsyncData(false);
      return null;
    }

    final result = await _startPeerLinkUsecase(const StartPeerLinkParams(isPermissionRequested: true));
    await _saveChoice(isEnabled: result.isSuccess);
    state = AsyncData(result.isSuccess);
    return result.fold(
      onFailure: (StartPeerLinkFailure failure) {
        return switch (failure) {
          StartPeerLinkFailure.permissionDenied => ref.l10n.exchangePermissionDenied,
          StartPeerLinkFailure.bluetoothOff => ref.l10n.exchangeBluetoothOff,
          StartPeerLinkFailure.unavailable => ref.l10n.exchangeUnavailable,
        };
      },
      onSuccess: (_) {
        return null;
      },
    );
  }

  /// Prend acte d'un arrêt venu d'Android : bouton de la notification, ou Bluetooth coupé.
  Future<void> _onStopped() async {
    state = const AsyncData(false);
    await _saveChoice(isEnabled: false);
  }

  /// Enregistre le choix de l'utilisateur.
  ///
  /// Les réglages sont relus puis réenregistrés en entier : les autres réglages ne doivent pas changer. Le notifier
  /// des réglages est rechargé, sinon sa copie périmée écraserait ce choix à sa prochaine écriture.
  ///
  /// - [isEnabled] : `true` si le transfert passif est actif.
  Future<void> _saveChoice({required bool isEnabled}) async {
    final settings = (await _getSettingsUsecase(const NoParams())).right;
    if (settings == null) {
      return;
    }
    await _saveSettingsUsecase(SaveSettingsParams(settings: settings.copyWith(isExchangeEnabled: isEnabled)));
    ref.invalidate(userSettingsNotifierProvider);
  }

  /// Note dans le journal un pair vu sans qu'un échange ait pu commencer.
  ///
  /// - [attempt] : pair concerné.
  Future<void> _logAttempt(PeerAttempt attempt) async {
    final now = DateTime.now();
    await _saveLog(
      ExchangeLog(
        id: UuidX.generate(),
        createdAt: now,
        updatedAt: now,
        peerAddress: attempt.peerAddress,
        outcome: attempt.outcome,
      ),
    );
  }

  /// Enregistre [log] et rafraîchit la page du journal.
  ///
  /// - [log] : trace à enregistrer.
  Future<void> _saveLog(ExchangeLog log) async {
    await _saveExchangeLogUsecase(SaveExchangeLogParams(log: log));
    ref.invalidate(exchangeLogsNotifierProvider);
  }

  /// Déroule un échange sur [transport], écarte ce que l'utilisateur n'accepte pas, recalcule les scores, puis fait
  /// respecter la limite de stockage.
  ///
  /// Les contenus de domaines absents de ses listes sont supprimés d'abord : le nettoyage n'a pas à sacrifier un
  /// contenu accepté pour faire de la place à ceux-là. Les scores vieillissent et les contenus reçus arrivent avec ceux du pair : sans ce recalcul, ils resteraient
  /// figés, et la prochaine offre proposerait toujours les mêmes contenus. Le nettoyage vient après, car il s'appuie
  /// sur ces scores.
  ///
  /// - [transport] : connexion avec le pair, fermée par la session à la fin.
  Future<void> _runSession(ExchangeTransportGateway transport) async {
    final session = ref.read(exchangeSessionProvider(transport));
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    _session = session;
    final result = await session.run();
    _session = null;
    stopwatch.stop();
    await _deleteUntrustedContentsUsecase(const NoParams());
    await _recalculateBroadcastScoresUsecase(const NoParams());
    await _recalculateDisplayScoresUsecase(const NoParams());
    await _recalculateSurvivalScoresUsecase(const NoParams());
    final removedContents = (await _enforceStorageLimitUsecase(const NoParams())).right ?? 0;
    final report = result.report;
    await _saveLog(
      ExchangeLog(
        id: UuidX.generate(),
        createdAt: startedAt,
        updatedAt: DateTime.now(),
        peerAddress: transport.peerAddress,
        outcome: _outcomeOf(result.failure),
        isInitiator: transport.isInitiator,
        duration: stopwatch.elapsed,
        awaitedFrame: result.awaitedFrame,
        sentBytes: result.sentBytes,
        receivedBytes: result.receivedBytes,
        importedContents: report?.importedContents ?? 0,
        rejectedContents: report?.rejectedContents ?? 0,
        importedReactions: report?.importedReactions ?? 0,
        rejectedReactions: report?.rejectedReactions ?? 0,
        removedContents: removedContents,
      ),
    );
    ref.read(exchangeStatsNotifierProvider.notifier).addResult(result);
    final failure = result.failure;
    if (failure != null) {
      AppLogger.warning('Échange interrompu : ${failure.name}');
    }
  }

  /// Traduit l'issue d'une session pour le journal.
  ///
  /// - [failure] : cause de l'échec, `null` si l'échange a réussi.
  ExchangeLogOutcome _outcomeOf(ExchangeSessionFailure? failure) {
    return switch (failure) {
      null => ExchangeLogOutcome.success,
      ExchangeSessionFailure.incompatibleVersion => ExchangeLogOutcome.incompatibleVersion,
      ExchangeSessionFailure.protocolViolation => ExchangeLogOutcome.protocolViolation,
      ExchangeSessionFailure.localError => ExchangeLogOutcome.localError,
      ExchangeSessionFailure.peerError => ExchangeLogOutcome.peerError,
      ExchangeSessionFailure.transportClosed => ExchangeLogOutcome.transportClosed,
      ExchangeSessionFailure.timeout => ExchangeLogOutcome.timeout,
      ExchangeSessionFailure.cancelled => ExchangeLogOutcome.cancelled,
    };
  }
}
