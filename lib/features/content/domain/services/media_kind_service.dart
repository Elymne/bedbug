import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extensions de fichier reconnues comme des vidéos.
const List<String> _videoExtensions = ['.mp4', '.webm', '.mov', '.m4v'];

/// Provider du [MediaKindService].
final mediaKindServiceProvider = Provider<MediaKindService>((ref) => const MediaKindService());

/// Déduit la nature d'un média (image, gif, vidéo) de son adresse.
///
/// Les hébergeurs servent leurs fichiers sous leur vraie extension
/// (`.gif`, `.mp4`) : c'est ce qui décide du lecteur à utiliser pour
/// afficher le média. Le fichier lui-même n'est jamais téléchargé pour ça.
class MediaKindService extends Service {
  /// Crée un [MediaKindService].
  const MediaKindService();

  /// Retourne la nature du média d'adresse [url], [MediaKind.image] par défaut.
  ///
  /// - [url] : adresse du média.
  MediaKind kindOf(String url) {
    final path = (Uri.tryParse(url)?.path ?? '').toLowerCase();
    if (_videoExtensions.any(path.endsWith)) {
      return MediaKind.video;
    }
    if (path.endsWith('.gif')) {
      return MediaKind.gif;
    }
    return MediaKind.image;
  }

  /// Retourne le média d'adresse [url], avec sa nature déduite de son extension.
  ///
  /// - [url] : adresse du média.
  ContentMedia mediaOf(String url) {
    return ContentMedia(url: url, kind: kindOf(url));
  }
}
