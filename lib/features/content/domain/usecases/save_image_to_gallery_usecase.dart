import 'package:bedbug/features/content/domain/gateways/image_gallery_gateway.dart';
import 'package:bedbug/features/content/infrastructure/gateways/gal_image_gallery_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/gallery_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveImageToGalleryUsecase].
final saveImageToGalleryUsecaseProvider = Provider<SaveImageToGalleryUsecase>((ref) {
  return SaveImageToGalleryUsecase(ref.read(imageGalleryGatewayProvider));
});

/// Enregistre une image d'un contenu dans la galerie du téléphone.
///
/// Les images reçues ne vivent que dans le stockage de l'app, qui les
/// supprime au gré du nettoyage automatique : l'utilisateur doit pouvoir
/// garder celles qui lui plaisent, hors de l'app. Distingue un refus d'accès
/// à la galerie, qu'il faut expliquer à l'utilisateur, des autres échecs.
class SaveImageToGalleryUsecase extends Usecase<SaveImageToGalleryParams, SaveImageToGalleryFailure, void> {
  /// Crée un [SaveImageToGalleryUsecase].
  SaveImageToGalleryUsecase(this._imageGalleryGateway);

  final ImageGalleryGateway _imageGalleryGateway;

  @override
  Future<Either<SaveImageToGalleryFailure, void>> call(SaveImageToGalleryParams params) async {
    try {
      await _imageGalleryGateway.saveImage(params.sourcePath);
      return const Right(null);
    } on GalleryException catch (error, stackTrace) {
      AppLogger.error('SaveImageToGalleryUsecase', error, stackTrace);
      if (error.isAccessDenied) {
        return const Left(SaveImageToGalleryFailure.accessDenied);
      }
      return const Left(SaveImageToGalleryFailure.saveError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveImageToGalleryUsecase', error, stackTrace);
      return const Left(SaveImageToGalleryFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveImageToGalleryUsecase].
enum SaveImageToGalleryFailure {
  /// L'utilisateur a refusé l'accès à sa galerie.
  accessDenied,

  /// L'image n'a pas pu être enregistrée (stockage plein, format refusé, erreur native).
  saveError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}

/// Paramètres du [SaveImageToGalleryUsecase].
class SaveImageToGalleryParams extends Params {
  /// Crée des [SaveImageToGalleryParams].
  ///
  /// - [sourcePath] : chemin absolu de l'image à enregistrer.
  const SaveImageToGalleryParams({required this.sourcePath});

  /// Chemin absolu de l'image à enregistrer.
  final String sourcePath;
}
