import 'package:bedbug/features/content/domain/gateways/image_compressor_gateway.dart';
import 'package:bedbug/features/content/domain/object_values/compressed_image.dart';
import 'package:bedbug/features/content/infrastructure/gateways/flutter_image_compress_image_compressor_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/image_compression_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille maximale du plus grand côté d'une image de contenu, en pixels.
///
/// Largement suffisant pour un affichage plein écran sur mobile ; au-delà,
/// les pixels supplémentaires ne font qu'alourdir le fichier.
const int maxContentImageDimension = 2048;

/// Poids maximal visé pour une image de contenu, en octets (500 Ko).
const int maxContentImageSizeInBytes = 500 * 1024;

/// Provider du [CompressImageUsecase].
final compressImageUsecaseProvider = Provider<CompressImageUsecase>(
  (ref) => CompressImageUsecase(ref.read(imageCompressorGatewayProvider)),
);

/// Recompresse une image avant qu'elle ne devienne un contenu.
///
/// Les photos prises par les smartphones récents pèsent plusieurs Mo pour une
/// résolution très supérieure à ce que l'app affiche. Ces images sont ensuite
/// stockées localement et transférées de pair à pair (BLE / Wi-Fi), où chaque
/// octet compte : on les ramène donc à [maxContentImageDimension] et sous
/// [maxContentImageSizeInBytes] dès leur import, une fois pour toutes, plutôt
/// que de payer leur poids d'origine à chaque stockage et chaque transfert.
class CompressImageUsecase extends Usecase<CompressImageParams, CompressImageFailure, CompressedImage> {
  /// Crée un [CompressImageUsecase].
  CompressImageUsecase(this._imageCompressorGateway);

  final ImageCompressorGateway _imageCompressorGateway;

  @override
  Future<Either<CompressImageFailure, CompressedImage>> call(CompressImageParams params) async {
    try {
      final image = await _imageCompressorGateway.compress(
        params.sourcePath,
        maxDimension: maxContentImageDimension,
        maxSizeInBytes: maxContentImageSizeInBytes,
      );
      return Right(image);
    } on ImageCompressionException catch (error, stackTrace) {
      AppLogger.error('CompressImageUsecase', error, stackTrace);
      return const Left(CompressImageFailure.compressionError);
    } catch (error, stackTrace) {
      AppLogger.error('CompressImageUsecase', error, stackTrace);
      return const Left(CompressImageFailure.unknown);
    }
  }
}

/// Échecs possibles du [CompressImageUsecase].
enum CompressImageFailure {
  /// L'image n'a pas pu être encodée (format non supporté, fichier corrompu).
  compressionError,

  /// Erreur inattendue lors de la compression.
  unknown,
}

/// Paramètres du [CompressImageUsecase].
class CompressImageParams extends Params {
  /// Crée des [CompressImageParams].
  ///
  /// - [sourcePath] : chemin absolu de l'image d'origine à recompresser.
  const CompressImageParams({required this.sourcePath});

  /// Chemin absolu de l'image d'origine.
  final String sourcePath;
}
