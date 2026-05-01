import 'package:flutter/foundation.dart';

/// Outil de log centralisé de l'application.
class AppLogger {
  /// Fond jaune, texte noir, gras.
  static const _yellow = '\x1B[43;30;1m';

  /// Fond rouge, texte blanc, gras.
  static const _red = '\x1B[41;97;1m';

  static const _reset = '\x1B[0m';

  /// Logue un message de niveau warning.
  static void warning(String message) {
    debugPrint('$_yellow ⚠ WARNING  $message $_reset');
  }

  /// Logue une erreur catchée dans un use case.
  ///
  /// - [usecase] : nom du use case où l'erreur a été catchée.
  /// - [error] : exception ou erreur capturée.
  /// - [stackTrace] : stack trace associée.
  static void error(String usecase, Object error, StackTrace stackTrace) {
    debugPrint('$_red ✖ ERROR  [$usecase] $_reset');
    debugPrint('$_red   ${error.runtimeType}: $error $_reset');
    for (final line in stackTrace.toString().trimRight().split('\n')) {
      debugPrint('$_red   $line $_reset');
    }
  }
}
