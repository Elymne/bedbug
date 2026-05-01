/// Classe de base abstraite pour les états des notifiers de l'application.
///
/// Toute classe représentant l'état d'un notifier doit étendre [NotifierState]
/// afin d'hériter de la gestion unifiée des erreurs.
abstract class NotifierState {
  NotifierState({required this.failureMessage});

  /// Message d'erreur à afficher en cas d'échec.
  ///
  /// Vaut `null` si aucune erreur n'est survenue.
  final String? failureMessage;
}
