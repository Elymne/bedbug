import 'dart:typed_data';

import 'package:bedbug/features/content/domain/object_values/media_file_format.dart';

/// Contrat du service d'enregistrement d'un média dans la galerie du téléphone.
///
/// Isolé derrière une interface pour que le domaine décide quoi enregistrer
/// (un média téléchargé et vérifié) sans dépendre du plugin natif utilisé.
abstract class MediaGalleryGateway {
  /// Enregistre [bytes], au format [format], dans la galerie du téléphone.
  ///
  /// Lève une `GalleryException` en cas d'échec, avec `isAccessDenied` à
  /// `true` si l'utilisateur refuse l'accès.
  ///
  /// - [bytes] : contenu du média.
  /// - [format] : format vérifié du média.
  Future<void> save(Uint8List bytes, MediaFileFormat format);
}
