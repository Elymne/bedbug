/// Format réel d'un fichier média, tel que reconnu par `MediaFormatService`.
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
}
