import 'dart:typed_data';

import 'package:bedbug/features/content/domain/gateways/media_gallery_gateway.dart';
import 'package:bedbug/features/content/domain/services/media_format_service.dart';
import 'package:bedbug/features/content/infrastructure/gateways/gal_media_gallery_gateway.dart';
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
  return SaveMediaToGalleryUsecase(ref.read(mediaGalleryGatewayProvider), ref.read(mediaFormatServiceProvider));
});

/// Enregistre un média déjà téléchargé dans la galerie du téléphone.
///
/// Les médias ne vivent plus dans l'app, seulement chez leur hébergeur, qui
/// peut les retirer à tout moment : l'utilisateur doit pouvoir garder ceux
/// qui lui plaisent. Le fichier n'est écrit que si ses octets sont bien ceux
/// d'une image ou d'une vidéo : la galerie ne doit jamais recevoir une page
/// web ou un exécutable déguisé.
class SaveMediaToGalleryUsecase extends Usecase<SaveMediaToGalleryParams, SaveMediaToGalleryFailure, void> {
  /// Crée un [SaveMediaToGalleryUsecase].
  SaveMediaToGalleryUsecase(this._mediaGalleryGateway, this._mediaFormatService);

  final MediaGalleryGateway _mediaGalleryGateway;

  final MediaFormatService _mediaFormatService;

  @override
  Future<Either<SaveMediaToGalleryFailure, void>> call(SaveMediaToGalleryParams params) async {
    try {
      final format = _mediaFormatService.detect(params.bytes);
      if (format == null) {
        return const Left(SaveMediaToGalleryFailure.unsupportedFormat);
      }

      await _mediaGalleryGateway.save(params.bytes, format);
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
  /// Le fichier n'est pas une image ou une vidéo d'un format accepté.
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
  /// - [bytes] : contenu du média, téléchargé par `FetchMediaUsecase`.
  const SaveMediaToGalleryParams({required this.bytes});

  /// Contenu du média.
  final Uint8List bytes;
}
