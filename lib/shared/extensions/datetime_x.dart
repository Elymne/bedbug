/// Extensions utilitaires sur [DateTime].
extension DateTimeX on DateTime {
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
