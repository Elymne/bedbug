import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/media/gallery.exception.dart';
import 'package:bedbug/gateways/media/media_gallery.gateway.dart';
import 'package:bedbug/gateways/media/media_gallery.gateway.gal.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/content/media_format.service.dart';
import 'package:bedbug/usecases/content/save_media_to_gallery/save_media_to_gallery.failure.dart';
import 'package:bedbug/usecases/content/save_media_to_gallery/save_media_to_gallery.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille maximale d'un média enregistré dans la galerie, en octets.
///
/// Plus large que pour l'affichage d'une image, pour laisser passer une
/// courte vidéo, mais bornée : le fichier est gardé en mémoire avant d'être
/// écrit.
const int maxGalleryMediaBytes = 50 * 1024 * 1024;

/// Provider du [SaveMediaToGalleryUsecase].
final saveMediaToGalleryUsecaseProvider = Provider<SaveMediaToGalleryUsecase>((ref) {
  return SaveMediaToGalleryUsecase(
    ref.read(mediaGalleryGatewayProvider),
    ref.read(mediaFormatServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
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
  SaveMediaToGalleryUsecase(this._mediaGalleryGateway, this._mediaFormatService, this._errorLogRepository);

  final MediaGalleryGateway _mediaGalleryGateway;

  final MediaFormatService _mediaFormatService;
  final ErrorLogRepository _errorLogRepository;

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
      await _errorLogRepository.record(source: 'SaveMediaToGalleryUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveMediaToGalleryFailure.saveError);
    }
  }
}
