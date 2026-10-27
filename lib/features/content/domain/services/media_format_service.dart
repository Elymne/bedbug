import 'dart:typed_data';

import 'package:bedbug/features/content/domain/object_values/media_file_format.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marques d'un conteneur ISO qui désignent des images (HEIF, AVIF), et non des vidéos.
const List<String> _isoImageBrands = ['heic', 'heix', 'mif1', 'msf1', 'avif', 'avis'];

/// Provider du [MediaFormatService].
final mediaFormatServiceProvider = Provider<MediaFormatService>((ref) => const MediaFormatService());

/// Reconnaît le format réel d'un fichier média à sa signature binaire.
///
/// L'extension d'une adresse et le type annoncé par le serveur sont choisis
/// par celui qui héberge le fichier : un « .jpg » peut contenir une page web
/// ou un exécutable. Avant d'écrire un fichier téléchargé dans la galerie du
/// téléphone, son format est donc vérifié sur ses premiers octets, et seuls
/// les formats d'image et de vidéo courants sont acceptés.
class MediaFormatService extends Service {
  /// Crée un [MediaFormatService].
  const MediaFormatService();

  /// Retourne le format reconnu dans [bytes], ou `null` si ce n'est pas un format accepté.
  ///
  /// - [bytes] : contenu du fichier.
  MediaFileFormat? detect(Uint8List bytes) {
    if (_startsWith(bytes, 0, const [0xFF, 0xD8, 0xFF])) {
      return MediaFileFormat.jpeg;
    }
    if (_startsWith(bytes, 0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return MediaFileFormat.png;
    }
    if (_startsWith(bytes, 0, 'GIF87a'.codeUnits) || _startsWith(bytes, 0, 'GIF89a'.codeUnits)) {
      return MediaFileFormat.gif;
    }
    if (_startsWith(bytes, 0, 'RIFF'.codeUnits) && _startsWith(bytes, 8, 'WEBP'.codeUnits)) {
      return MediaFileFormat.webp;
    }
    if (_startsWith(bytes, 0, const [0x1A, 0x45, 0xDF, 0xA3])) {
      return MediaFileFormat.webm;
    }
    // Conteneur ISO : la boîte `ftyp` suit la taille de la première boîte, et la marque la suit.
    if (_startsWith(bytes, 4, 'ftyp'.codeUnits) && bytes.length >= 12) {
      if (_startsWith(bytes, 8, 'qt  '.codeUnits)) {
        return MediaFileFormat.quickTime;
      }
      // Les images HEIF/AVIF partagent ce conteneur : elles ne sont pas des vidéos.
      if (_isoImageBrands.any((brand) => _startsWith(bytes, 8, brand.codeUnits))) {
        return null;
      }
      return MediaFileFormat.mp4;
    }
    return null;
  }

  /// Indique si [bytes] contient [signature] à partir de la position [offset].
  ///
  /// - [bytes] : contenu du fichier.
  /// - [offset] : position du premier octet comparé.
  /// - [signature] : octets attendus.
  bool _startsWith(Uint8List bytes, int offset, List<int> signature) {
    if (bytes.length < offset + signature.length) {
      return false;
    }
    for (var index = 0; index < signature.length; index++) {
      if (bytes[offset + index] != signature[index]) {
        return false;
      }
    }
    return true;
  }
}
