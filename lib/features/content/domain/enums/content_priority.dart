/// Priorité d'un contenu, utilisée pour déterminer l'ordre de suppression
/// automatique lors d'un nettoyage du stockage local.
///
/// Du moins prioritaire (supprimé en premier) au plus prioritaire
/// (supprimé en dernier) : [public] → [subscribed] → [favorited] → [owned].
enum ContentPriority {
  /// Contenu public sans sub associé.
  ///
  /// Supprimé en priorité lors d'un nettoyage automatique.
  public,

  /// Contenu provenant d'un sub auquel l'utilisateur est abonné.
  subscribed,

  /// Contenu ajouté en favori par l'utilisateur.
  favorited,

  /// Contenu créé par l'utilisateur lui-même.
  ///
  /// Jamais supprimé automatiquement sauf décision explicite.
  owned,
}
