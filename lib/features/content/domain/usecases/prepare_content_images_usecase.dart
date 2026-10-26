import 'dart:io';

import 'package:bedbug/features/content/domain/object_values/compressed_image.dart';
import 'package:bedbug/features/content/domain/object_values/content_image.dart';
import 'package:bedbug/features/content/domain/usecases/compress_image_usecase.dart';
import 'package:bedbug/shared/config/content_image_storage.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider du [PrepareContentImagesUsecase].
final prepareContentImagesUsecaseProvider = Provider<PrepareContentImagesUsecase>((ref) {
  return PrepareContentImagesUsecase(ref.read(compressImageUsecaseProvider));
});

/// Prépare les images choisies pour un nouveau contenu : les recompresse puis les copie dans le dossier images de l'app.
///
/// Les images choisies dans la galerie restent hors de l'app et peuvent y
/// disparaître : un contenu doit donc posséder ses propres fichiers, déjà
/// recompressés pour le stockage et le transfert (voir
/// [CompressImageUsecase]). Toutes les images sont compressées avant
/// d'écrire le moindre fichier : un échec sur l'une d'elles n'abandonne ainsi
/// aucun fichier orphelin. La compression est séquentielle, pour ne pas
/// décoder jusqu'à dix photos en mémoire en même temps.
class PrepareContentImagesUsecase
    extends Usecase<PrepareContentImagesParams, PrepareContentImagesFailure, List<ContentImage>> {
  /// Crée un [PrepareContentImagesUsecase].
  PrepareContentImagesUsecase(this._compressImageUsecase);

  final CompressImageUsecase _compressImageUsecase;

  @override
  Future<Either<PrepareContentImagesFailure, List<ContentImage>>> call(PrepareContentImagesParams params) async {
    try {
      final compressedImages = <CompressedImage>[];
      for (final sourcePath in params.sourcePaths) {
        final result = await _compressImageUsecase(
          CompressImageParams(sourcePath: sourcePath, imageCount: params.sourcePaths.length),
        );
        final compressedImage = result.right;
        if (compressedImage == null) {
          return const Left(PrepareContentImagesFailure.compressionError);
        }
        compressedImages.add(compressedImage);
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final imagesDirectory = Directory('${documentsDirectory.path}/$contentImagesFolder');
      await imagesDirectory.create(recursive: true);
      final contentImages = <ContentImage>[];
      for (final compressedImage in compressedImages) {
        final fileName = '${UuidX.generate()}.${compressedImage.fileExtension}';
        await File('${imagesDirectory.path}/$fileName').writeAsBytes(compressedImage.bytes);
        contentImages.add(
          ContentImage(fileName: fileName, width: compressedImage.width, height: compressedImage.height),
        );
      }
      return Right(contentImages);
    } on FileSystemException catch (error, stackTrace) {
      AppLogger.error('PrepareContentImagesUsecase', error, stackTrace);
      return const Left(PrepareContentImagesFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('PrepareContentImagesUsecase', error, stackTrace);
      return const Left(PrepareContentImagesFailure.unknown);
    }
  }
}

/// Échecs possibles du [PrepareContentImagesUsecase].
enum PrepareContentImagesFailure {
  /// L'une des images n'a pas pu être recompressée.
  compressionError,

  /// Les fichiers n'ont pas pu être écrits dans le dossier images de l'app.
  storageError,

  /// Erreur inattendue lors de la préparation.
  unknown,
}

/// Paramètres du [PrepareContentImagesUsecase].
class PrepareContentImagesParams extends Params {
  /// Crée des [PrepareContentImagesParams].
  ///
  /// - [sourcePaths] : chemins absolus des images choisies, dans l'ordre d'affichage.
  const PrepareContentImagesParams({required this.sourcePaths});

  /// Chemins absolus des images choisies, dans l'ordre d'affichage.
  final List<String> sourcePaths;
}
