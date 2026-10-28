import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider du [LocaleNotifier].
final localeNotifierProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Notifier gérant la locale active de l'application.
///
/// Initialise depuis les préférences persistées, sinon depuis la locale système,
/// sinon en français. Persiste chaque changement via [SharedPreferences].
class LocaleNotifier extends Notifier<Locale> {
  /// Codes des langues proposées, dans l'ordre d'affichage du sélecteur de langue.
  ///
  /// Un code par fichier `.arb` : en ajouter un ici à chaque nouvelle langue.
  /// `zh` désigne le chinois simplifié.
  static const List<String> supportedCodes = ['fr', 'es', 'it', 'ar', 'zh'];

  /// Langue utilisée quand ni la préférence enregistrée ni la langue du téléphone ne sont proposées.
  ///
  /// Le français, langue de référence des traductions : c'est celle dont les
  /// textes sont toujours à jour.
  static const String _fallbackCode = 'fr';

  /// Clé de la langue choisie dans les [SharedPreferences].
  static const String _prefsKey = 'locale';

  @override
  Locale build() {
    _loadFromPrefs();
    final code = PlatformDispatcher.instance.locale.languageCode;
    return Locale(supportedCodes.contains(code) ? code : _fallbackCode);
  }

  /// Met à jour la locale active et la persiste en local.
  ///
  /// - [locale] : nouvelle locale, dont la langue doit faire partie de [supportedCodes].
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Charge la locale persistée et met à jour le state si elle est encore proposée.
  ///
  /// Une langue retirée depuis (l'anglais, par exemple) est ignorée : la
  /// langue du téléphone ou le français prennent le relais.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedCodes.contains(code)) {
      state = Locale(code);
    }
  }
}
