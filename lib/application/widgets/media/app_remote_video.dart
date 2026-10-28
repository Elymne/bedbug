import 'package:bedbug/application/notifiers/remote_video_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/media/app_media_placeholder.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Vidéo distante, lue à la demande, qui remplit la place que lui donne son parent.
///
/// Rien n'est chargé tant que l'utilisateur n'a pas touché la vidéo : dans
/// le fil, elle n'est qu'une vignette ([isPlayable] à `false`), et c'est la
/// page de détail qui permet de la lire. Une fois lancée, un tap met en
/// pause ou relance la lecture. Comme pour les images, ce widget ne décide
/// pas si la vidéo peut être chargée : c'est le rôle de `AppRemoteMedia`.
class AppRemoteVideo extends ConsumerWidget {
  /// Crée un [AppRemoteVideo].
  ///
  /// - [url] : adresse de la vidéo, telle que reçue.
  /// - [isPlayable] : `false` pour une simple vignette, sans lecture possible (défaut `true`).
  const AppRemoteVideo({super.key, required this.url, this.isPlayable = true});

  /// Adresse de la vidéo, telle que reçue.
  final String url;

  /// Indique si la vidéo peut être lancée depuis ce widget.
  final bool isPlayable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    if (!isPlayable) {
      return const AppMediaPlaceholder(icon: Icons.play_circle_outline, isDark: true);
    }

    final remoteVideoNotifierWatcher = ref.watch(remoteVideoNotifierProvider(url));

    return remoteVideoNotifierWatcher.when(
      loading: () {
        return const ColoredBox(
          color: AppColors.onLightDeep,
          child: Center(child: CircularProgressIndicator(color: AppColors.onDark)),
        );
      },
      error: (error, stackTrace) {
        return AppMediaPlaceholder(icon: Icons.videocam_off_outlined, label: l10n.mediaUnavailable, isDark: true);
      },
      data: (controller) {
        if (controller == null) {
          return Semantics(
            button: true,
            label: l10n.videoPlayLabel,
            child: GestureDetector(
              onTap: () => ref.read(remoteVideoNotifierProvider(url).notifier).play(),
              child: const AppMediaPlaceholder(icon: Icons.play_circle_outline, isDark: true),
            ),
          );
        }
        return GestureDetector(
          onTap: () => controller.value.isPlaying ? controller.pause() : controller.play(),
          child: ColoredBox(
            color: AppColors.onLightDeep,
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(controller),
                    // Seule l'icône de pause se reconstruit au rythme de la lecture.
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) {
                        if (controller.value.isPlaying) {
                          return const SizedBox.shrink();
                        }
                        return const Center(child: Icon(Icons.play_arrow_rounded, size: 56, color: AppColors.onDark));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
