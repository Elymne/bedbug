import 'dart:async';

import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/screens/exchange/exchange.screen.dart';
import 'package:bedbug/application/screens/exchange/exchange_scene/exchange_scene.widget.dart';
import 'package:bedbug/application/screens/home/home.screen.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.widget.dart';
import 'package:bedbug/application/widgets/signature/app_bedbug_frames.widget.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/gateways/exchange/exchange_transport/exchange_transport.gateway.dart';
import 'package:bedbug/gateways/exchange/peer_link/peer_link.gateway.ble.dart';
import 'package:bedbug/gateways/exchange/peer_link/peer_link.gateway.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.failure.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.result.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.usecase.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.failure.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.usecase.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.failure.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.params.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_error_log_repository.dart';
import '../helpers/find_app_icon.dart';
import '../helpers/pump_app.dart';

/// Fausse recherche de pairs, dont les réponses sont fixées par le test.
class _FakePeerLinkGateway implements PeerLinkGateway {
  _FakePeerLinkGateway({this.isPermissionGranted = true});

  /// Réponse à la demande de permissions.
  final bool isPermissionGranted;

  /// Arrêts de la recherche, déclenchés par le test comme le ferait la notification.
  final StreamController<void> stopController = StreamController.broadcast();

  @override
  Stream<ExchangeTransportGateway> get connections {
    return const Stream.empty();
  }

  @override
  Stream<PeerAttempt> get attempts {
    return const Stream.empty();
  }

  @override
  Stream<void> get stopped {
    return stopController.stream;
  }

  @override
  Future<bool> requestPermissions() async {
    return isPermissionGranted;
  }

  @override
  Future<PeerLinkStartStatus> start() async {
    return PeerLinkStartStatus.started;
  }

  @override
  Future<void> stop() async {}

  /// Ferme le flux des arrêts.
  Future<void> close() {
    return stopController.close();
  }
}

/// Fake [GetSettingsUsecase] et [SaveSettingsUsecase] : les réglages vivent en mémoire.
class _FakeSettings {
  /// Réglages enregistrés.
  UserSettings settings = defaultUserSettings;
}

/// Fake [GetSettingsUsecase] lisant des réglages en mémoire.
class _FakeGetSettingsUsecase implements GetSettingsUsecase {
  _FakeGetSettingsUsecase(this._store);
  final _FakeSettings _store;

  @override
  Future<Either<GetSettingsFailure, UserSettings>> call(NoParams params) async => Right(_store.settings);
}

/// Fake [SaveSettingsUsecase] écrivant des réglages en mémoire.
class _FakeSaveSettingsUsecase implements SaveSettingsUsecase {
  _FakeSaveSettingsUsecase(this._store);
  final _FakeSettings _store;

  @override
  Future<Either<SaveSettingsFailure, UserSettings>> call(SaveSettingsParams params) async {
    _store.settings = params.settings;
    return Right(params.settings);
  }
}

/// Fake [GetHomeFeedUsecase] retournant un fil vide.
class _FakeGetHomeFeedUsecase implements GetHomeFeedUsecase {
  @override
  Future<Either<GetHomeFeedFailure, HomeFeed>> call(NoParams params) async {
    return const Right(HomeFeed(contents: [], unviewedContentIds: {}));
  }
}

/// Retourne l'état de l'échange vu par la page : `true` le jour (échange actif), `false` la nuit.
///
/// - [tester] : testeur du widget.
bool? _isExchangeEnabled(WidgetTester tester) {
  final container = ProviderScope.containerOf(tester.element(find.byType(ExchangeScene)));
  return container.read(passiveExchangeNotifierProvider).value;
}

void main() {
  late _FakeSettings store;

  setUp(() {
    store = _FakeSettings();
  });

  testWidgets('le choix est enregistré, et l\'échange reprend tout seul au lancement suivant', (tester) async {
    store.settings = defaultUserSettings.copyWith(blockedUrls: ['a'], isExchangeEnabled: true);
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway(isPermissionGranted: false)),
        errorLogRepositoryProvider.overrideWithValue(FakeErrorLogRepository()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();
    expect(_isExchangeEnabled(tester), isTrue);

    await tester.tap(find.byType(AppBedbugFrames));
    await tester.pump();
    await tester.pump();

    expect(_isExchangeEnabled(tester), isFalse);
    expect(store.settings.isExchangeEnabled, isFalse);
    expect(store.settings.blockedUrls, ['a']);
  });

  testWidgets('toucher le bedbug active l\'échange, puis le coupe', (tester) async {
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway()),
        errorLogRepositoryProvider.overrideWithValue(FakeErrorLogRepository()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();
    expect(_isExchangeEnabled(tester), isFalse);

    await tester.tap(find.byType(AppBedbugFrames));
    await tester.pump();
    await tester.pump();
    expect(_isExchangeEnabled(tester), isTrue);

    await tester.tap(find.byType(AppBedbugFrames));
    await tester.pump();
    await tester.pump();
    expect(_isExchangeEnabled(tester), isFalse);
  });

  testWidgets('la nuit revient si les permissions sont refusées', (tester) async {
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway(isPermissionGranted: false)),
        errorLogRepositoryProvider.overrideWithValue(FakeErrorLogRepository()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(AppBedbugFrames));
    await tester.pump();
    await tester.pump();

    expect(_isExchangeEnabled(tester), isFalse);
    // Le bedbug se fâche le temps que l'erreur s'affiche, puis se rendort.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('(╬ Ò﹏Ó)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('(╬ Ò﹏Ó)'), findsNothing);
    expect(find.text('(－_－) zzZ'), findsOneWidget);
  });

  testWidgets('la nuit tombe quand l\'échange est arrêté depuis la notification', (tester) async {
    final gateway = _FakePeerLinkGateway();
    addTearDown(gateway.close);
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(gateway),
        errorLogRepositoryProvider.overrideWithValue(FakeErrorLogRepository()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(AppBedbugFrames));
    await tester.pump();
    await tester.pump();

    gateway.stopController.add(null);
    await tester.pump();
    await tester.pump();

    expect(_isExchangeEnabled(tester), isFalse);
  });

  testWidgets('l\'icône du menu s\'anime seulement quand l\'échange est actif', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway()),
        errorLogRepositoryProvider.overrideWithValue(FakeErrorLogRepository()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
        getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase()),
      ],
    );
    await tester.pump();
    await tester.pump();

    AppGhostEffect exchangeIcon() {
      final finder = find.ancestor(of: findAppIcon(AppIcons.bluetooth), matching: find.byType(AppGhostEffect));
      return tester.widget<AppGhostEffect>(finder.first);
    }

    expect(exchangeIcon().isAnimating, isFalse);

    final context = tester.element(find.byType(HomeScreen));
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ExchangeScreen())));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(AppBedbugFrames));
    await tester.pump();
    await tester.pump();
    Navigator.of(tester.element(find.byType(ExchangeScreen))).pop();
    await tester.pump(const Duration(seconds: 1));

    expect(exchangeIcon().isAnimating, isTrue);
  });
}
