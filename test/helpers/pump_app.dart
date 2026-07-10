import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monte [child] dans un arbre de widgets minimal (localisation + Riverpod)
/// pour les tests unitaires de vue.
///
/// - [overrides] : overrides Riverpod à appliquer (repositories, usecases...).
Future<void> pumpApp(WidgetTester tester, Widget child, {List<Override> overrides = const []}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: child,
      ),
    ),
  );
}
