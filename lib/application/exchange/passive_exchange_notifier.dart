import 'dart:async';

import 'package:bedbug/application/exchange/exchange_session.dart';
import 'package:bedbug/application/exchange/exchange_stats_notifier.dart';
import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/screens/settings/user_settings_notifier.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_broadcast_scores_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_display_scores_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_survival_scores_usecase.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/usecases/start_peer_link_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/stop_peer_link_usecase.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_peer_link_gateway.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
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

  /// Recherche de pairs, dont sont écoutés les connexions et les arrêts.
  late final _peerLinkGateway = ref.read(peerLinkGatewayProvider);

  /// Session en cours, `null` entre deux rencontres.
  ExchangeSession? _session;

  @override
  Future<bool> build() async {
    final connections = _peerLinkGateway.connections.listen((transport) => unawaited(_runSession(transport)));
    final stopped = _peerLinkGateway.stopped.listen((_) => unawaited(_onStopped()));
    ref.onDispose(() {
      unawaited(connections.cancel());
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

  /// Déroule un échange sur [transport], puis recalcule les scores.
  ///
  /// Les scores vieillissent et les contenus reçus arrivent avec ceux du pair : sans ce recalcul, ils resteraient
  /// figés, et la prochaine offre proposerait toujours les mêmes contenus.
  ///
  /// - [transport] : connexion avec le pair, fermée par la session à la fin.
  Future<void> _runSession(ExchangeTransportGateway transport) async {
    final session = ref.read(exchangeSessionProvider(transport));
    _session = session;
    final result = await session.run();
    _session = null;
    await _recalculateBroadcastScoresUsecase(const NoParams());
    await _recalculateDisplayScoresUsecase(const NoParams());
    await _recalculateSurvivalScoresUsecase(const NoParams());
    ref.read(exchangeStatsNotifierProvider.notifier).addResult(result);
    final failure = result.failure;
    if (failure != null) {
      AppLogger.warning('Échange interrompu : ${failure.name}');
    }
  }
}
