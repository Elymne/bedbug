import 'package:bedbug/usecases/content/fetch_link_preview/fetch_link_preview.usecase.dart';

/// Échecs possibles du [FetchLinkPreviewUsecase].
enum FetchLinkPreviewFailure {
  /// L'adresse du lien est piégée ou mal formée.
  invalidUrl,

  /// Le domaine du lien n'est pas dans la whitelist de liens : il ne doit pas être contacté.
  untrustedDomain,

  /// La page n'a pas pu être lue (réseau, délai dépassé, redirection, réponse vide).
  unavailable,

  /// Erreur inattendue.
  unknown,
}
