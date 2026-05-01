import 'dart:ui';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider Riverpod gérant la locale active de l'application.
///
/// Initialisé par défaut avec le français (`fr`) via [lookupAppLocalizations].
/// Peut être mis à jour à l'exécution pour changer la langue de l'interface :
/// ```dart
/// ref.read(appLocalizationsProvider.notifier).state = lookupAppLocalizations(const Locale('en'));
/// ```
final appLocalizationsProvider = StateProvider<AppLocalizations>((ref) {
  return lookupAppLocalizations(const Locale('fr'));
});

/// Extension sur [Ref] pour accéder aux traductions depuis un notifier ou un provider.
///
/// Exemple d'utilisation dans un notifier :
/// ```dart
/// final message = ref.l10n.title;
/// ```
extension L10nRefX on Ref {
  /// Retourne l'instance [AppLocalizations] injectée via [appLocalizationsProvider].
  AppLocalizations get l10n => read(appLocalizationsProvider);
}
