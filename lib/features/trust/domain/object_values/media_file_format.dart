import 'dart:typed_data';

/// Format réel d'un fichier média, reconnu à sa signature binaire.
///
/// L'extension d'une adresse et le type annoncé par le serveur sont choisis
/// par celui qui héberge le fichier : un « .jpg » peut contenir une page web
/// ou un exécutable. Avant d'écrire un fichier téléchargé dans la galerie du
/// téléphone, son format est donc vérifié sur ses premiers octets, et seuls
/// les formats d'image et de vidéo courants sont acceptés.
enum MediaFileFormat {
  /// Image JPEG.
  jpeg(extension: 'jpg', isVideo: false),

  /// Image PNG.
  png(extension: 'png', isVideo: false),

  /// Image GIF, animée ou non.
  gif(extension: 'gif', isVideo: false),

  /// Image WebP.
  webp(extension: 'webp', isVideo: false),

  /// Vidéo MP4 (conteneur ISO, marque autre que QuickTime).
  mp4(extension: 'mp4', isVideo: true),

  /// Vidéo QuickTime.
  quickTime(extension: 'mov', isVideo: true),

  /// Vidéo WebM.
  webm(extension: 'webm', isVideo: true);

  /// Crée un [MediaFileFormat].
  ///
  /// - [extension] : extension de fichier, sans le point.
  /// - [isVideo] : `true` pour une vidéo, `false` pour une image.
  const MediaFileFormat({required this.extension, required this.isVideo});

  /// Extension de fichier, sans le point.
  final String extension;

  /// Indique si le format est une vidéo.
  final bool isVideo;

  /// Retourne le format reconnu dans [bytes], ou `null` si ce n'est pas un format accepté.
  ///
  /// - [bytes] : contenu du fichier.
  static MediaFileFormat? fromBytes(Uint8List bytes) {
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
      for (final imageBrand in const ['heic', 'heix', 'mif1', 'msf1', 'avif', 'avis']) {
        if (_startsWith(bytes, 8, imageBrand.codeUnits)) {
          return null;
        }
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
  static bool _startsWith(Uint8List bytes, int offset, List<int> signature) {
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
