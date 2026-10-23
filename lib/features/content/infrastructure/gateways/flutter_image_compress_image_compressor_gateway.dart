import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bedbug/features/content/domain/gateways/image_compressor_gateway.dart';
import 'package:bedbug/features/content/domain/object_values/compressed_image.dart';
import 'package:bedbug/shared/exceptions/image_compression_exception.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qualité d'encodage de la première tentative.
const int _initialQuality = 85;

/// Pas de diminution de la qualité entre deux tentatives.
const int _qualityStep = 10;

/// Qualité minimale en dessous de laquelle on préfère réduire les dimensions
/// plutôt que dégrader davantage l'image.
const int _minQuality = 55;

/// Facteur appliqué au plus grand côté quand la qualité plancher ne suffit pas.
const double _downscaleFactor = 0.8;

/// Plus grand côté minimal, en pixels, en dessous duquel on arrête de réduire
/// et on accepte le meilleur résultat obtenu même s'il dépasse le poids visé.
const int _minDimension = 640;

/// Provider du [FlutterImageCompressImageCompressorGateway].
final imageCompressorGatewayProvider = Provider<ImageCompressorGateway>(
  (ref) => FlutterImageCompressImageCompressorGateway(),
);

/// Implémentation de [ImageCompressorGateway] utilisant `flutter_image_compress`.
///
/// Encode en WebP : à qualité égale, le fichier est nettement plus léger
/// qu'en JPEG, et la transparence des PNG est conservée.
class FlutterImageCompressImageCompressorGateway implements ImageCompressorGateway {
  /// Crée un [FlutterImageCompressImageCompressorGateway].
  FlutterImageCompressImageCompressorGateway();

  @override
  Future<CompressedImage> compress(String sourcePath, {required int maxDimension, required int maxSizeInBytes}) async {
    final sourceSize = await _readSize(await File(sourcePath).readAsBytes());
    final sourceLongSide = math.max(sourceSize.width, sourceSize.height);
    final sourceShortSide = math.min(sourceSize.width, sourceSize.height);

    var longSide = math.min(sourceLongSide, maxDimension);
    var quality = _initialQuality;

    while (true) {
      // `flutter_image_compress` réduit l'image jusqu'à ce que son plus petit
      // côté atteigne la valeur demandée (sans jamais agrandir). On lui passe
      // donc le petit côté correspondant au grand côté visé : le ratio est
      // conservé et le résultat ne dépend pas de l'orientation EXIF.
      final shortSide = math.max(1, (sourceShortSide * longSide / sourceLongSide).round());
      final bytes = await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: shortSide,
        minHeight: shortSide,
        quality: quality,
        format: CompressFormat.webp,
      );
      if (bytes == null) {
        throw ImageCompressionException('FlutterImageCompressImageCompressorGateway', 'Unable to encode $sourcePath');
      }

      final isUnderLimit = bytes.length <= maxSizeInBytes;
      final nextLongSide = (longSide * _downscaleFactor).round();
      final isAtFloor = quality - _qualityStep < _minQuality && nextLongSide < _minDimension;
      if (isUnderLimit || isAtFloor) {
        final size = await _readSize(bytes);
        return CompressedImage(bytes: bytes, width: size.width, height: size.height, fileExtension: 'webp');
      }

      if (quality - _qualityStep >= _minQuality) {
        quality -= _qualityStep;
        continue;
      }
      longSide = nextLongSide;
    }
  }

  /// Lit les dimensions de l'image encodée [bytes] sans la décoder entièrement.
  ///
  /// - [bytes] : octets de l'image encodée.
  Future<({int width, int height})> _readSize(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = (width: descriptor.width, height: descriptor.height);
    descriptor.dispose();
    buffer.dispose();
    return size;
  }
}
