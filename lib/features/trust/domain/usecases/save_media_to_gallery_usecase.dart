import 'package:bedbug/features/trust/domain/gateways/media_gallery_gateway.dart';
import 'package:bedbug/features/trust/domain/object_values/media_file_format.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/trust/domain/usecases/fetch_media_usecase.dart';
import 'package:bedbug/features/trust/infrastructure/gateways/gal_media_gallery_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/gallery_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille maximale d'un média enregistré dans la galerie, en octets.
///
/// Plus large que pour l'affichage d'une image, pour laisser passer une
/// courte vidéo, mais bornée : le fichier est gardé en mémoire avant d'être
/// écrit.
const int maxGalleryMediaBytes = 50 * 1024 * 1024;

/// Provider du [SaveMediaToGalleryUsecase].
final saveMediaToGalleryUsecaseProvider = Provider<SaveMediaToGalleryUsecase>((ref) {
  return SaveMediaToGalleryUsecase(ref.read(fetchMediaUsecaseProvider), ref.read(mediaGalleryGatewayProvider));
});

/// Télécharge un média distant et l'enregistre dans la galerie du téléphone.
///
/// Les médias ne vivent plus dans l'app, seulement chez leur hébergeur, qui
/// peut les retirer à tout moment : l'utilisateur doit pouvoir garder ceux
/// qui lui plaisent. Le téléchargement passe par [FetchMediaUsecase], avec
/// les mêmes vérifications que l'affichage, et le fichier n'est écrit que si
/// ses octets sont bien ceux d'une image ou d'une vidéo : la galerie ne doit
/// jamais recevoir une page web ou un exécutable déguisé.
class SaveMediaToGalleryUsecase extends Usecase<SaveMediaToGalleryParams, SaveMediaToGalleryFailure, void> {
  /// Crée un [SaveMediaToGalleryUsecase].
  SaveMediaToGalleryUsecase(this._fetchMediaUsecase, this._mediaGalleryGateway);

  final FetchMediaUsecase _fetchMediaUsecase;

  final MediaGalleryGateway _mediaGalleryGateway;

  @override
  Future<Either<SaveMediaToGalleryFailure, void>> call(SaveMediaToGalleryParams params) async {
    try {
      final fetched = await _fetchMediaUsecase(
        FetchMediaParams(
          rawUrl: params.rawUrl,
          policy: params.policy,
          isConfirmed: params.isConfirmed,
          maxBytes: maxGalleryMediaBytes,
        ),
      );
      final fetchedMedia = fetched.right;
      if (fetchedMedia == null) {
        return Left(switch (fetched.left!) {
          FetchMediaFailure.tooLarge => SaveMediaToGalleryFailure.tooLarge,
          _ => SaveMediaToGalleryFailure.unavailable,
        });
      }

      final format = MediaFileFormat.fromBytes(fetchedMedia.bytes);
      if (format == null) {
        return const Left(SaveMediaToGalleryFailure.unsupportedFormat);
      }

      await _mediaGalleryGateway.save(fetchedMedia.bytes, format);
      return const Right(null);
    } on GalleryException catch (error, stackTrace) {
      AppLogger.error('SaveMediaToGalleryUsecase', error, stackTrace);
      if (error.isAccessDenied) {
        return const Left(SaveMediaToGalleryFailure.accessDenied);
      }
      return const Left(SaveMediaToGalleryFailure.saveError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveMediaToGalleryUsecase', error, stackTrace);
      return const Left(SaveMediaToGalleryFailure.saveError);
    }
  }
}

/// Échecs possibles du [SaveMediaToGalleryUsecase].
enum SaveMediaToGalleryFailure {
  /// Le média n'a pas pu être téléchargé (adresse ou domaine refusé, introuvable, réseau).
  unavailable,

  /// Le média dépasse [maxGalleryMediaBytes].
  tooLarge,

  /// Le fichier téléchargé n'est pas une image ou une vidéo d'un format accepté.
  unsupportedFormat,

  /// L'utilisateur a refusé l'accès à sa galerie.
  accessDenied,

  /// Le média n'a pas pu être écrit (stockage plein, format refusé par la galerie, erreur native).
  saveError,
}

/// Paramètres du [SaveMediaToGalleryUsecase].
class SaveMediaToGalleryParams extends Params {
  /// Crée des [SaveMediaToGalleryParams].
  ///
  /// - [rawUrl] : adresse du média, telle que reçue.
  /// - [policy] : politique de confiance des médias de l'utilisateur.
  /// - [isConfirmed] : `true` si l'utilisateur a confirmé vouloir afficher ce média malgré un domaine inconnu.
  const SaveMediaToGalleryParams({required this.rawUrl, required this.policy, this.isConfirmed = false});

  /// Adresse du média, telle que reçue.
  final String rawUrl;

  /// Politique de confiance des médias de l'utilisateur.
  final UrlTrustPolicy policy;

  /// Indique si l'utilisateur a confirmé vouloir afficher ce média malgré un domaine inconnu.
  final bool isConfirmed;
}
