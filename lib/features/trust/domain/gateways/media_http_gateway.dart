import 'dart:typed_data';

import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';

/// Requêtes HTTP vers un média distant, une requête à la fois, sans jamais suivre de redirection.
///
/// Suivre une redirection automatiquement, c'est laisser un site de
/// confiance envoyer le téléphone vers n'importe quel autre site, et
/// contourner les listes de domaines. Les redirections sont donc remontées
/// telles quelles : c'est au domaine de décider s'il faut les suivre.
abstract class MediaHttpGateway {
  /// Effectue une requête GET vers [url] et retourne la réponse, sans suivre de redirection.
  ///
  /// - [url] : URL vérifiée à contacter.
  /// - [maxBytes] : taille maximale acceptée pour le corps de la réponse.
  /// - [isBodyNeeded] : `false` pour seulement vérifier que le média répond (vidéo lue ensuite par le lecteur).
  Future<MediaHttpResponse> get(SafeUrl url, {required int maxBytes, required bool isBodyNeeded});
}

/// Réponse à une requête de [MediaHttpGateway].
sealed class MediaHttpResponse {
  const MediaHttpResponse();
}

/// Le média a répondu avec succès.
final class MediaHttpBody extends MediaHttpResponse {
  /// Crée un [MediaHttpBody].
  ///
  /// - [bytes] : contenu du média, vide si le corps n'était pas demandé.
  const MediaHttpBody(this.bytes);

  /// Contenu du média, vide si le corps n'était pas demandé.
  final Uint8List bytes;
}

/// Le serveur redirige vers une autre adresse.
final class MediaHttpRedirect extends MediaHttpResponse {
  /// Crée un [MediaHttpRedirect].
  ///
  /// - [location] : adresse de destination, telle que donnée par le serveur (éventuellement relative).
  const MediaHttpRedirect(this.location);

  /// Adresse de destination, telle que donnée par le serveur (éventuellement relative).
  final String location;
}

/// La requête a échoué.
final class MediaHttpError extends MediaHttpResponse {
  /// Crée un [MediaHttpError].
  ///
  /// - [kind] : nature de l'échec.
  const MediaHttpError(this.kind);

  /// Nature de l'échec.
  final MediaHttpErrorKind kind;
}

/// Nature d'un échec de [MediaHttpGateway].
enum MediaHttpErrorKind {
  /// Le média n'existe pas (404, 410).
  notFound,

  /// Le média dépasse la taille maximale acceptée.
  tooLarge,

  /// Réponse inattendue du serveur, ou réseau indisponible.
  unavailable,
}
