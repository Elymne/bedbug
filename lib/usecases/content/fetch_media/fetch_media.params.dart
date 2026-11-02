import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/url_trust_policy.value_object.dart';
import 'package:bedbug/usecases/content/fetch_media/fetch_media.usecase.dart';

/// Paramètres du [FetchMediaUsecase].
class FetchMediaParams extends Params {
  /// Crée des [FetchMediaParams].
  ///
  /// - [rawUrl] : adresse du média, telle que reçue.
  /// - [policy] : politique de confiance des médias de l'utilisateur.
  /// - [isConfirmed] : `true` si l'utilisateur a confirmé vouloir afficher ce média malgré un domaine inconnu.
  /// - [isBodyNeeded] : `false` pour seulement vérifier l'adresse finale (vidéo lue ensuite par le lecteur).
  /// - [maxBytes] : taille maximale acceptée (défaut [maxImageBytes]).
  const FetchMediaParams({
    required this.rawUrl,
    required this.policy,
    this.isConfirmed = false,
    this.isBodyNeeded = true,
    this.maxBytes = maxImageBytes,
  });

  /// Adresse du média, telle que reçue.
  final String rawUrl;

  /// Politique de confiance des médias de l'utilisateur.
  final UrlTrustPolicy policy;

  /// Indique si l'utilisateur a confirmé vouloir afficher ce média malgré un domaine inconnu.
  final bool isConfirmed;

  /// Indique si le contenu du média doit être téléchargé.
  final bool isBodyNeeded;

  /// Taille maximale acceptée, en octets.
  final int maxBytes;
}
