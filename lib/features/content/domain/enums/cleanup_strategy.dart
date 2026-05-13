/// Stratégie de suppression automatique des contenus lors d'un nettoyage
/// du stockage local.
enum CleanupStrategy {
  /// Supprime en suivant l'ordre de priorité des contenus :
  /// public → subscribed → favorited → owned.
  byPriority(0),

  /// Supprime les contenus les plus anciens en premier,
  /// quelle que soit leur priorité.
  byDate(1),

  /// Supprime par priorité d'abord, puis par date au sein
  /// d'une même priorité. Stratégie par défaut recommandée.
  byPriorityThenDate(2);

  const CleanupStrategy(this.value);

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;
}
