import 'package:bedbug/usecases/content/fetch_media/fetch_media.usecase.dart';

/// Échecs possibles du [FetchMediaUsecase].
enum FetchMediaFailure {
  /// L'adresse, d'origine ou de redirection, est piégée ou mal formée.
  invalidUrl,

  /// L'adresse, d'origine ou de redirection, vise un domaine non accepté.
  untrustedDomain,

  /// Trop de redirections successives.
  tooManyRedirects,

  /// Le média n'existe pas.
  notFound,

  /// Le média dépasse la taille maximale acceptée.
  tooLarge,

  /// Serveur ou réseau indisponible, ou erreur inattendue.
  unavailable,
}
