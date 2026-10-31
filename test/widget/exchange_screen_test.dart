import 'dart:async';

import 'package:bedbug/application/screens/exchange/exchange_screen.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/peer_link_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_peer_link_gateway.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  UserSettings settings = const UserSettings.empty();
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
  Future<Either<GetHomeFeedFailure, List<Content>>> call(NoParams params) async => const Right([]);
}

/// Retourne la valeur affichée par la case à cocher.
///
/// - [tester] : testeur du widget.
bool? _checkboxValue(WidgetTester tester) {
  return tester.widget<Checkbox>(find.byType(Checkbox)).value;
}

void main() {
  late _FakeSettings store;

  setUp(() {
    store = _FakeSettings();
  });

  testWidgets('le choix est enregistré, et l\'échange reprend tout seul au lancement suivant', (tester) async {
    store.settings = const UserSettings(blockedUrls: ['a'], blockedWords: [], isExchangeEnabled: true);
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway(isPermissionGranted: false)),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();
    expect(_checkboxValue(tester), isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();

    expect(_checkboxValue(tester), isFalse);
    expect(store.settings.isExchangeEnabled, isFalse);
    expect(store.settings.blockedUrls, ['a']);
  });

  testWidgets('la case active l\'échange puis le coupe', (tester) async {
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();
    expect(_checkboxValue(tester), isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();
    expect(_checkboxValue(tester), isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();
    expect(_checkboxValue(tester), isFalse);
  });

  testWidgets('la case reste décochée si les permissions sont refusées', (tester) async {
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway(isPermissionGranted: false)),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();

    expect(_checkboxValue(tester), isFalse);
  });

  testWidgets('la case se décoche quand l\'échange est arrêté depuis la notification', (tester) async {
    final gateway = _FakePeerLinkGateway();
    addTearDown(gateway.close);
    await pumpApp(
      tester,
      const ExchangeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(gateway),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
      ],
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();

    gateway.stopController.add(null);
    await tester.pump();
    await tester.pump();

    expect(_checkboxValue(tester), isFalse);
  });

  testWidgets('l\'icône du menu s\'anime seulement quand l\'échange est actif', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [
        peerLinkGatewayProvider.overrideWithValue(_FakePeerLinkGateway()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase(store)),
        saveSettingsUsecaseProvider.overrideWithValue(_FakeSaveSettingsUsecase(store)),
        getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase()),
      ],
    );
    await tester.pump();
    await tester.pump();

    AppGhostEffect exchangeIcon() {
      final finder = find.ancestor(of: find.byIcon(Icons.bluetooth), matching: find.byType(AppGhostEffect));
      return tester.widget<AppGhostEffect>(finder.first);
    }

    expect(exchangeIcon().isAnimating, isFalse);

    final context = tester.element(find.byType(HomeScreen));
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ExchangeScreen())));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();
    Navigator.of(tester.element(find.byType(ExchangeScreen))).pop();
    await tester.pump(const Duration(seconds: 1));

    expect(exchangeIcon().isAnimating, isTrue);
  });
}
