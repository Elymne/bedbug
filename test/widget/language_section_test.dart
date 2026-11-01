import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/l10n/locale_notifier.dart';
import 'package:bedbug/application/screens/settings/settings_section_screen.dart';
import 'package:bedbug/application/screens/settings/widgets/language_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/find_app_icon.dart';

/// Monte la [LanguageSection] dans une app dont la locale suit le [LocaleNotifier], comme `AppRoot`.
Future<void> _pumpLanguageSection(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          return MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: ref.watch(localeNotifierProvider),
            home: const Scaffold(body: LanguageSection()),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'locale': 'fr'});
  });

  testWidgets('propose chaque langue écrite dans sa propre langue', (tester) async {
    await _pumpLanguageSection(tester);

    for (final name in ['Français', 'Español', 'Italiano', 'العربية', '简体中文']) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets("choisir l'arabe fait passer l'interface de droite à gauche, et l'enregistre", (tester) async {
    await _pumpLanguageSection(tester);
    expect(Directionality.of(tester.element(find.byType(LanguageSection))), TextDirection.ltr);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(Directionality.of(tester.element(find.byType(LanguageSection))), TextDirection.rtl);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'ar');
  });

  testWidgets('le titre de la page suit la langue choisie depuis la page elle-même', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: ref.watch(localeNotifierProvider),
              home: SettingsSectionScreen(
                titleOf: (l10n) => l10n.settingsLanguageTitle,
                child: const LanguageSection(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(lookupAppLocalizations(const Locale('fr')).settingsLanguageTitle), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text(lookupAppLocalizations(const Locale('ar')).settingsLanguageTitle), findsOneWidget);
  });

  testWidgets("une langue enregistrée qui n'est plus proposée est ignorée", (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    await _pumpLanguageSection(tester);

    expect(Directionality.of(tester.element(find.byType(LanguageSection))), TextDirection.ltr);
    expect(findAppIcon(AppIcons.check), findsOneWidget);
  });
}
