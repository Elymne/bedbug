import 'package:bedbug/features/content/domain/gateways/image_gallery_gateway.dart';
import 'package:bedbug/shared/exceptions/gallery_exception.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

/// Qualité JPEG de l'image enregistrée : assez haute pour ne pas dégrader une image déjà compressée.
const int _kJpegQuality = 95;

/// Provider du [GalImageGalleryGateway].
final imageGalleryGatewayProvider = Provider<ImageGalleryGateway>((ref) => GalImageGalleryGateway());

/// Implémentation d'[ImageGalleryGateway] utilisant `gal`, après conversion en JPEG avec `flutter_image_compress`.
///
/// Les images des contenus sont stockées en WebP, que toutes les galeries
/// n'acceptent pas (iOS en particulier) : elles sont donc converties en JPEG,
/// format accepté partout, avant d'être enregistrées.
class GalImageGalleryGateway implements ImageGalleryGateway {
  /// Crée un [GalImageGalleryGateway].
  GalImageGalleryGateway();

  @override
  Future<void> saveImage(String sourcePath) async {
    final jpegBytes = await FlutterImageCompress.compressWithFile(
      sourcePath,
      quality: _kJpegQuality,
      format: CompressFormat.jpeg,
    );
    if (jpegBytes == null) {
      throw GalleryException('GalImageGalleryGateway', 'Unable to convert $sourcePath to JPEG');
    }

    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        throw const GalleryException('GalImageGalleryGateway', 'Gallery access denied', isAccessDenied: true);
      }
      await Gal.putImageBytes(jpegBytes, name: 'bedbug_${DateTime.now().millisecondsSinceEpoch}');
    } on GalException catch (error) {
      throw GalleryException(
        'GalImageGalleryGateway',
        error,
        isAccessDenied: error.type == GalExceptionType.accessDenied,
      );
    }
  }
}
