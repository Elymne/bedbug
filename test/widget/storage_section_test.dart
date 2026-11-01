import 'package:bedbug/application/screens/settings/widgets/storage_section.dart';
import 'package:bedbug/features/content/domain/entities/storage.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/usecases/enforce_storage_limit_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_storage_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_survival_scores_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_storage_limit_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Construit un [Storage] de limite [limitInBytes].
///
/// - [limitInBytes] : limite, en octets.
Storage _buildStorage(int limitInBytes) {
  final date = DateTime(2026, 10);
  return Storage(id: 'storage', createdAt: date, updatedAt: date, maxSizeInBytes: limitInBytes);
}

/// Fake [GetStorageUsecase] retournant une limite fixe.
class _FakeGetStorageUsecase implements GetStorageUsecase {
  _FakeGetStorageUsecase(this._limitInBytes);
  final int _limitInBytes;

  @override
  Future<Either<GetStorageFailure, Storage>> call(NoParams params) async {
    return Right(_buildStorage(_limitInBytes));
  }
}

/// Fake [SaveStorageLimitUsecase] retenant les limites reçues.
class _FakeSaveStorageLimitUsecase implements SaveStorageLimitUsecase {
  /// Limites enregistrées, dans l'ordre.
  final List<int> savedLimits = [];

  @override
  Future<Either<SaveStorageLimitFailure, Storage>> call(SaveStorageLimitParams params) async {
    savedLimits.add(params.maxSizeInBytes);
    return Right(_buildStorage(params.maxSizeInBytes));
  }
}

/// Fake [RecalculateSurvivalScoresUsecase] sans effet.
class _FakeRecalculateSurvivalScoresUsecase implements RecalculateSurvivalScoresUsecase {
  @override
  Future<Either<RecalculateSurvivalScoresFailure, void>> call(NoParams params) async {
    return const Right(null);
  }
}

/// Fake [EnforceStorageLimitUsecase] comptant ses appels.
class _FakeEnforceStorageLimitUsecase implements EnforceStorageLimitUsecase {
  /// Nombre d'appels reçus.
  int callCount = 0;

  @override
  Future<Either<EnforceStorageLimitFailure, int>> call(NoParams params) async {
    callCount++;
    return const Right(0);
  }
}

void main() {
  late _FakeSaveStorageLimitUsecase saveUsecase;
  late _FakeEnforceStorageLimitUsecase enforceUsecase;

  /// Monte la section avec une limite actuelle de [limitInBytes].
  Future<void> pumpSection(WidgetTester tester, int limitInBytes) async {
    saveUsecase = _FakeSaveStorageLimitUsecase();
    enforceUsecase = _FakeEnforceStorageLimitUsecase();
    await pumpApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: StorageSection())),
      overrides: [
        getStorageUsecaseProvider.overrideWithValue(_FakeGetStorageUsecase(limitInBytes)),
        saveStorageLimitUsecaseProvider.overrideWithValue(saveUsecase),
        recalculateSurvivalScoresUsecaseProvider.overrideWithValue(_FakeRecalculateSurvivalScoresUsecase()),
        enforceStorageLimitUsecaseProvider.overrideWithValue(enforceUsecase),
      ],
    );
    await tester.pumpAndSettle();
  }

  /// Choisit l'option personnalisée et laisse le champ prendre le focus.
  ///
  /// Le halo du champ actif tourne en boucle : `pumpAndSettle` ne rendrait pas la main.
  Future<void> selectCustomOption(WidgetTester tester) async {
    await tester.tap(find.text('Personnalisée'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('propose les trois limites et coche la limite actuelle', (tester) async {
    await pumpSection(tester, defaultMaxStorageSizeInBytes);

    expect(find.text('50 Mo'), findsOneWidget);
    expect(find.text('100 Mo'), findsOneWidget);
    expect(find.text('250 Mo'), findsOneWidget);
    final selected = find.ancestor(of: find.text('100 Mo'), matching: find.byType(ListTile));
    expect(find.descendant(of: selected, matching: find.byIcon(Icons.check)), findsOneWidget);
  });

  testWidgets('un tap sur une limite proposée l\'enregistre et nettoie le stockage', (tester) async {
    await pumpSection(tester, defaultMaxStorageSizeInBytes);

    await tester.tap(find.text('50 Mo'));
    await tester.pumpAndSettle();

    expect(saveUsecase.savedLimits, [50 * bytesPerMegabyte]);
    expect(enforceUsecase.callCount, 1);
  });

  testWidgets('le champ reste désactivé tant que l\'option personnalisée n\'est pas choisie', (tester) async {
    await pumpSection(tester, defaultMaxStorageSizeInBytes);

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.check)).onPressed, isNull);
  });

  testWidgets('l\'option personnalisée active le champ, y place le curseur et n\'enregistre rien', (tester) async {
    await pumpSection(tester, defaultMaxStorageSizeInBytes);

    await selectCustomOption(tester);

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    final customOption = find.ancestor(of: find.text('Personnalisée'), matching: find.byType(ListTile));
    expect(find.descendant(of: customOption, matching: find.byIcon(Icons.check)), findsOneWidget);
    final previousOption = find.ancestor(of: find.text('100 Mo'), matching: find.byType(ListTile));
    expect(find.descendant(of: previousOption, matching: find.byIcon(Icons.check)), findsNothing);
    expect(saveUsecase.savedLimits, isEmpty);
  });

  testWidgets('revenir sur une limite proposée désactive le champ', (tester) async {
    await pumpSection(tester, defaultMaxStorageSizeInBytes);
    await selectCustomOption(tester);

    await tester.tap(find.text('50 Mo'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(saveUsecase.savedLimits, [50 * bytesPerMegabyte]);
    final selected = find.ancestor(of: find.text('50 Mo'), matching: find.byType(ListTile));
    expect(find.descendant(of: selected, matching: find.byIcon(Icons.check)), findsOneWidget);
  });

  testWidgets('une limite personnalisée s\'applique à la validation, pas à la frappe', (tester) async {
    await pumpSection(tester, defaultMaxStorageSizeInBytes);
    await selectCustomOption(tester);

    await tester.enterText(find.byType(TextField), '75');
    await tester.pump();
    expect(saveUsecase.savedLimits, isEmpty);

    await tester.tap(find.byTooltip('Appliquer'));
    await tester.pumpAndSettle();

    expect(saveUsecase.savedLimits, [75 * bytesPerMegabyte]);
  });

  testWidgets('une limite hors des bornes est refusée', (tester) async {
    await pumpSection(tester, defaultMaxStorageSizeInBytes);
    await selectCustomOption(tester);

    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.byTooltip('Appliquer'));
    // Le champ refusé garde le focus et son halo tourne en boucle : `pumpAndSettle` ne rendrait jamais la main.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(saveUsecase.savedLimits, isEmpty);
    expect(find.text('Entre un nombre entre 1 et 1000.'), findsOneWidget);
  });

  testWidgets('préremplit et active le champ quand la limite actuelle est personnalisée', (tester) async {
    await pumpSection(tester, 75 * bytesPerMegabyte);

    expect(find.widgetWithText(TextField, '75'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    final customOption = find.ancestor(of: find.text('Personnalisée'), matching: find.byType(ListTile));
    expect(find.descendant(of: customOption, matching: find.byIcon(Icons.check)), findsOneWidget);
  });
}
