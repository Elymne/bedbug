import 'package:bedbug/application/notifiers/revealed_urls_notifier.dart';
import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/features/content/domain/usecases/fetch_media_usecase.dart';
import 'package:bedbug/shared/config/http_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Provider du [RemoteVideoNotifier], un par adresse de vidéo.
final remoteVideoNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<RemoteVideoNotifier, VideoPlayerController?, String>(RemoteVideoNotifier.new);

/// Notifier préparant la lecture d'une vidéo distante, à la demande de l'utilisateur.
///
/// Le lecteur vidéo suit les redirections tout seul : lui confier
/// directement l'adresse reçue contournerait les listes de domaines. La
/// vidéo n'est donc confiée au lecteur qu'une fois son adresse finale
/// trouvée, chaque redirection vérifiée par [FetchMediaUsecase]. Rien n'est
/// chargé tant que l'utilisateur n'a pas lancé la lecture, pour ne pas
/// consommer de données à chaque passage dans le fil. Le lecteur est libéré
/// dès que plus rien n'affiche la vidéo.
class RemoteVideoNotifier extends AsyncNotifier<VideoPlayerController?> {
  /// Crée un [RemoteVideoNotifier].
  ///
  /// - [url] : adresse de la vidéo, telle que reçue.
  RemoteVideoNotifier(this.url);

  /// Adresse de la vidéo, telle que reçue.
  final String url;

  /// Cas d'usage de chargement d'un média, qui vérifie chaque redirection.
  late final _fetchMediaUsecase = ref.read(fetchMediaUsecaseProvider);

  @override
  Future<VideoPlayerController?> build() async {
    return null;
  }

  /// Vérifie l'adresse de la vidéo, prépare le lecteur et lance la lecture en boucle.
  ///
  /// En cas d'échec (domaine refusé, vidéo introuvable, réseau), l'état
  /// passe en erreur et le widget affiche son état d'erreur.
  Future<void> play() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final trustSettings = await ref.read(trustSettingsNotifierProvider.future);
      final result = await _fetchMediaUsecase(
        FetchMediaParams(
          rawUrl: url,
          policy: trustSettings.mediaPolicy,
          isConfirmed: ref.read(revealedUrlsNotifierProvider).contains(url),
          isBodyNeeded: false,
        ),
      );
      final fetchedMedia = result.right;
      if (fetchedMedia == null) {
        throw StateError('Vidéo refusée ou indisponible : ${result.left}');
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(fetchedMedia.url.url),
        httpHeaders: const {'User-Agent': appUserAgent},
      );
      ref.onDispose(controller.dispose);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      return controller;
    });
  }
}
