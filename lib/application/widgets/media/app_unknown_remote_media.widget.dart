import 'package:bedbug/application/notifiers/revealed_urls.notifier.dart';
import 'package:bedbug/application/widgets/media/app_media_veil.widget.dart';
import 'package:bedbug/application/widgets/media/app_remote_image.widget.dart';
import 'package:bedbug/application/widgets/media/app_remote_video.widget.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Média distant d'un domaine classé nulle part : rien n'est chargé tant que l'utilisateur ne l'a pas dévoilé.
///
/// Affiche le voile qui montre le domaine et propose de dévoiler le média ; une fois dévoilé (sur confirmation, voir
/// [AppMediaVeil]), le média est chargé et affiché. Seule partie de `AppRemoteMedia` à observer les médias dévoilés :
/// un dévoilement ne reconstruit que les médias de domaines inconnus.
class AppUnknownRemoteMedia extends ConsumerWidget {
  /// Crée un [AppUnknownRemoteMedia].
  ///
  /// - [media] : média à afficher.
  /// - [host] : domaine du média, affiché sur le voile.
  /// - [fit] : façon de faire tenir une image dans sa place.
  /// - [isPlayable] : `true` pour qu'une vidéo puisse être lue ici, `false` pour une vignette.
  /// - [isOmittedWhenNotAllowed] : `true` pour ne rien afficher plutôt que le voile, quand le média est décoratif.
  const AppUnknownRemoteMedia({
    super.key,
    required this.media,
    required this.host,
    required this.fit,
    required this.isPlayable,
    required this.isOmittedWhenNotAllowed,
  });

  /// Média à afficher.
  final ContentMedia media;

  /// Domaine du média, affiché sur le voile.
  final String host;

  /// Façon de faire tenir une image dans sa place.
  final BoxFit fit;

  /// Indique si une vidéo peut être lue ici.
  final bool isPlayable;

  /// Indique si rien ne doit être affiché plutôt que le voile.
  final bool isOmittedWhenNotAllowed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revealedUrls = ref.watch(revealedUrlsNotifierProvider);
    if (!revealedUrls.contains(media.url)) {
      if (isOmittedWhenNotAllowed) {
        return const SizedBox.shrink();
      }
      return AppMediaVeil(url: media.url, host: host);
    }

    return switch (media.kind) {
      MediaKind.video => AppRemoteVideo(url: media.url, isPlayable: isPlayable),
      MediaKind.image || MediaKind.gif => AppRemoteImage(url: media.url, isConfirmed: true, fit: fit),
    };
  }
}
