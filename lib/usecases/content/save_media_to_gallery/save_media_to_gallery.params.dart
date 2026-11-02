import 'dart:typed_data';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/content/save_media_to_gallery/save_media_to_gallery.usecase.dart';

/// Paramètres du [SaveMediaToGalleryUsecase].
class SaveMediaToGalleryParams extends Params {
  /// Crée des [SaveMediaToGalleryParams].
  ///
  /// - [bytes] : contenu du média, téléchargé par `FetchMediaUsecase`.
  const SaveMediaToGalleryParams({required this.bytes});

  /// Contenu du média.
  final Uint8List bytes;
}
