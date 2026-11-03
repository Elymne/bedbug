import 'dart:typed_data';

import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';
import 'package:bedbug/usecases/content/fetch_media/fetch_media.usecase.dart';

/// Média téléchargé par le [FetchMediaUsecase].
class FetchedMedia {
  /// Crée un [FetchedMedia].
  ///
  /// - [url] : adresse finale, après redirections.
  /// - [bytes] : contenu du média, vide s'il n'était pas demandé.
  const FetchedMedia({required this.url, required this.bytes});

  /// Adresse finale, après redirections vérifiées.
  final SafeUrl url;

  /// Contenu du média, vide s'il n'était pas demandé.
  final Uint8List bytes;
}
