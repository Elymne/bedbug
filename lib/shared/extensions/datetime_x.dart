import 'package:bedbug/application/l10n/generated/app_localizations.dart';

/// Extensions utilitaires sur [DateTime].
extension DateTimeX on DateTime {
  /// Retourne une durée écoulée depuis cette date, écrite en toutes lettres et traduite.
  ///
  /// Version longue de [timeAgo], pour les écrans où la place ne manque pas
  /// (page de détail d'un contenu) : `Il y a 6 jours` plutôt que `6j`.
  /// Exemples : `À l'instant`, `Il y a une heure`, `Il y a une journée`,
  /// `Il y a 3 mois`.
  ///
  /// - [l10n] : traductions de la langue courante.
  String timeAgoLong(AppLocalizations l10n) {
    final diff = DateTime.now().difference(this);

    if (diff.inMinutes < 60) {
      return l10n.timeAgoMinutes(diff.inMinutes.clamp(0, 59));
    }
    if (diff.inHours < 24) {
      return l10n.timeAgoHours(diff.inHours);
    }
    if (diff.inDays < 30) {
      return l10n.timeAgoDays(diff.inDays);
    }
    if (diff.inDays < 365) {
      return l10n.timeAgoMonths((diff.inDays / 30).floor());
    }
    return l10n.timeAgoYears((diff.inDays / 365).floor());
  }

  /// Retourne une durée écoulée depuis cette date au format court.
  ///
  /// Exemples : `1min`, `3h`, `4j`, `2 mois`, `1 an`.
  String get timeAgo {
    final diff = DateTime.now().difference(this);

    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}j';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} mois';
    return '${(diff.inDays / 365).floor()} an';
  }
}
