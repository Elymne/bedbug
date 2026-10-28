import 'dart:io';
import 'dart:typed_data';

import 'package:bedbug/features/content/domain/gateways/media_gallery_gateway.dart';
import 'package:bedbug/features/content/domain/object_values/media_file_format.dart';
import 'package:bedbug/shared/exceptions/gallery_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Provider du [GalMediaGalleryGateway].
final mediaGalleryGatewayProvider = Provider<MediaGalleryGateway>((ref) => GalMediaGalleryGateway());

/// Implémentation de [MediaGalleryGateway] utilisant `gal`.
///
/// Une image est confiée directement en mémoire. `gal` n'accepte une vidéo
/// que depuis un fichier : elle est écrite dans le dossier temporaire de
/// l'app, sous un nom choisi ici (jamais celui de l'adresse), puis supprimée
/// une fois copiée dans la galerie.
class GalMediaGalleryGateway implements MediaGalleryGateway {
  /// Crée un [GalMediaGalleryGateway].
  GalMediaGalleryGateway();

  @override
  Future<void> save(Uint8List bytes, MediaFileFormat format) async {
    final name = 'bedbug_${DateTime.now().millisecondsSinceEpoch}';
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        throw const GalleryException('GalMediaGalleryGateway', 'Gallery access denied', isAccessDenied: true);
      }
      if (!format.isVideo) {
        await Gal.putImageBytes(bytes, name: name);
        return;
      }

      final file = File('${(await getTemporaryDirectory()).path}/$name.${format.extension}');
      try {
        await file.writeAsBytes(bytes, flush: true);
        await Gal.putVideo(file.path);
      } finally {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } on GalException catch (error) {
      throw GalleryException(
        'GalMediaGalleryGateway',
        error,
        isAccessDenied: error.type == GalExceptionType.accessDenied,
      );
    }
  }
}
