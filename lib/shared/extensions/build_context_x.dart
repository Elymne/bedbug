import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Extension sur [BuildContext] pour accéder aux traductions sans vérification de null.
///
/// Exemple d'utilisation :
/// ```dart
/// context.loc.title
/// ```
extension BuildContextX on BuildContext {
  /// Retourne l'instance [AppLocalizations] associée au contexte courant.
  ///
  /// Lève une [Exception] si les localisations sont absentes du contexte,
  /// ce qui indique que le [MaterialApp] n'est pas configuré avec les délégués requis.
  AppLocalizations get loc {
    final l = AppLocalizations.of(this);
    if (l == null) {
      throw Exception('AppLocalizations not found! Make sure your context is under MaterialApp with delegates.');
    }
    return l;
  }

  /// Récupère la largeur du context du widget courant.
  double get width => MediaQuery.of(this).size.width;

  /// Récupère la hauteur du context du widget courant.
  double get height => MediaQuery.of(this).size.height;
}
