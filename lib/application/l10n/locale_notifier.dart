import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeNotifierProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Notifier gérant la locale active de l'application.
///
/// Initialise depuis les préférences persistées, sinon depuis la locale système.
/// Persiste chaque changement via [SharedPreferences].
class LocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'locale';
  static const _supportedCodes = ['fr', 'en'];

  @override
  Locale build() {
    _loadFromPrefs();
    final code = PlatformDispatcher.instance.locale.languageCode;
    return _supportedCodes.contains(code) ? Locale(code) : const Locale('en');
  }

  /// Charge la locale persistée et met à jour le state si présente.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && _supportedCodes.contains(code)) {
      state = Locale(code);
    }
  }

  /// Met à jour la locale active et la persiste en local.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
