import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/select_options/select_options_screen.dart';
import 'package:bedbug/application/widgets/fields/app_select_box.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../helpers/find_app_icon.dart';

/// Options communes aux tests.
const List<AppSelectOption<String>> _kOptions = [
  AppSelectOption(value: 'molle', label: 'Molle'),
  AppSelectOption(value: 'gugi', label: 'Gugi'),
  AppSelectOption(value: 'rock-salt', label: 'Rock Salt'),
];

/// Monte une [AppSelectBox] dont la page des options est celle de l'application.
Future<void> _pumpSelectBox(WidgetTester tester, FormControl<String> control) async {
  final router = GoRouter(
    initialLocation: '/box',
    routes: [
      GoRoute(
        path: '/box',
        builder: (context, state) {
          return Scaffold(
            body: AppSelectBox<String>(control: control, label: 'Police', options: _kOptions),
          );
        },
      ),
      GoRoute(
        path: selectOptionsPath,
        builder: (context, state) => SelectOptionsScreen(params: state.extra! as SelectOptionsParams),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    ),
  );
}

/// Ouvre la page des options depuis le champ affichant [selectedLabel].
Future<void> _openOptions(WidgetTester tester, String selectedLabel) async {
  await tester.tap(find.text(selectedLabel));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le label et la valeur choisie', (tester) async {
    await _pumpSelectBox(tester, FormControl<String>(value: 'gugi'));

    expect(find.text('Police'), findsOneWidget);
    expect(find.text('Gugi'), findsOneWidget);
  });

  testWidgets('la page montre le label, le filtre, puis les options séparées', (tester) async {
    await _pumpSelectBox(tester, FormControl<String>(value: 'gugi'));
    await _openOptions(tester, 'Gugi');

    expect(find.byType(SelectOptionsScreen), findsOneWidget);
    expect(find.text('Police'), findsOneWidget);
    expect(find.text('Filtrer…'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.byType(AppListSeparator), findsNWidgets(2));
    expect(findAppIcon(AppIcons.check), findsOneWidget);
  });

  testWidgets('choisir une option met à jour le contrôle et referme la page', (tester) async {
    final control = FormControl<String>(value: 'gugi');
    await _pumpSelectBox(tester, control);
    await _openOptions(tester, 'Gugi');

    await tester.tap(find.text('Rock Salt'));
    await tester.pumpAndSettle();

    expect(control.value, 'rock-salt');
    expect(find.byType(SelectOptionsScreen), findsNothing);
    expect(find.text('Rock Salt'), findsOneWidget);
  });

  testWidgets('revenir sans choisir laisse la valeur en place', (tester) async {
    final control = FormControl<String>(value: 'gugi');
    await _pumpSelectBox(tester, control);
    await _openOptions(tester, 'Gugi');

    await tester.tap(findAppIcon(AppIcons.arrowBack));
    await tester.pumpAndSettle();

    expect(control.value, 'gugi');
    expect(find.byType(SelectOptionsScreen), findsNothing);
  });

  testWidgets('le filtre ignore la casse et ne s\'applique qu\'après 0,3 s sans frappe', (tester) async {
    await _pumpSelectBox(tester, FormControl<String>(value: 'gugi'));
    await _openOptions(tester, 'Gugi');

    await tester.enterText(find.byType(TextField), 'RO');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'ROC');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ListTile), findsNWidgets(3), reason: 'la seconde frappe doit relancer le délai');

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Rock Salt'), findsOneWidget);
    expect(find.byType(AppListSeparator), findsNothing);
  });

  testWidgets('un filtre sans correspondance affiche le message dédié', (tester) async {
    await _pumpSelectBox(tester, FormControl<String>(value: 'gugi'));
    await _openOptions(tester, 'Gugi');

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Aucun résultat'), findsOneWidget);
  });

  testWidgets('fermer la page pendant le délai du filtre ne laisse rien en attente', (tester) async {
    await _pumpSelectBox(tester, FormControl<String>(value: 'gugi'));
    await _openOptions(tester, 'Gugi');

    await tester.enterText(find.byType(TextField), 'ro');
    await tester.tap(findAppIcon(AppIcons.arrowBack));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SelectOptionsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
