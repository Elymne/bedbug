import 'package:bedbug/application/notifiers/revealed_urls_notifier.dart';
import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/widgets/media/app_media_placeholder.dart';
import 'package:bedbug/application/widgets/media/app_media_veil.dart';
import 'package:bedbug/application/widgets/media/app_remote_image.dart';
import 'package:bedbug/application/widgets/media/app_remote_video.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Média distant (image, gif ou vidéo), affiché selon le niveau de confiance de son domaine.
///
/// Seul point d'entrée pour afficher un média venu d'ailleurs : c'est ici
/// que la politique de confiance de l'utilisateur décide de ce qui est
/// chargé.
/// - Domaine de confiance : affiché.
/// - Greylist : chargé mais flouté, dévoilé sur confirmation.
/// - Domaine inconnu : rien n'est chargé, le domaine est affiché, dévoilé sur confirmation.
/// - Adresse piégée : jamais chargée.
///
/// Remplit la place que lui donne son parent.
class AppRemoteMedia extends ConsumerWidget {
  /// Crée un [AppRemoteMedia].
  ///
  /// - [media] : média à afficher.
  /// - [fit] : façon de faire tenir une image dans sa place (défaut [BoxFit.cover]).
  /// - [isPlayable] : `true` pour qu'une vidéo puisse être lue ici, `false` pour une vignette (défaut `false`).
  /// - [isOmittedWhenNotAllowed] : `true` pour ne rien afficher plutôt qu'un voile ou une erreur, quand le
  ///   média est décoratif (aperçu d'un lien).
  const AppRemoteMedia({
    super.key,
    required this.media,
    this.fit = BoxFit.cover,
    this.isPlayable = false,
    this.isOmittedWhenNotAllowed = false,
  });

  /// Média à afficher.
  final ContentMedia media;

  /// Façon de faire tenir une image dans sa place.
  final BoxFit fit;

  /// Indique si une vidéo peut être lue ici.
  final bool isPlayable;

  /// Indique si rien ne doit être affiché quand le média n'est pas affichable directement.
  final bool isOmittedWhenNotAllowed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustSettingsNotifierWatcher = ref.watch(trustSettingsNotifierProvider);
    final revealedUrls = ref.watch(revealedUrlsNotifierProvider);
    final trustSettings = trustSettingsNotifierWatcher.value;
    if (trustSettings == null) {
      return const AppMediaPlaceholder(icon: Icons.image_outlined);
    }

    final isRevealed = revealedUrls.contains(media.url);
    final trust = trustSettings.mediaPolicy.evaluate(media.url);
    final host = SafeUrl.tryParse(media.url)?.host;

    if (trust == UrlTrust.invalid || host == null) {
      if (isOmittedWhenNotAllowed) {
        return const SizedBox.shrink();
      }
      return AppMediaPlaceholder(icon: Icons.broken_image_outlined, label: context.loc.mediaUnavailable);
    }
    if (trust == UrlTrust.unknown && !isRevealed) {
      if (isOmittedWhenNotAllowed) {
        return const SizedBox.shrink();
      }
      return AppMediaVeil(url: media.url, host: host);
    }
    if (trust == UrlTrust.grey && !isRevealed) {
      // Une vidéo ne se floute pas sans être chargée : elle est voilée comme un domaine inconnu.
      return AppMediaVeil(
        url: media.url,
        host: host,
        blurredChild: media.kind == MediaKind.video ? null : AppRemoteImage(url: media.url, isConfirmed: false),
      );
    }

    return switch (media.kind) {
      MediaKind.video => AppRemoteVideo(url: media.url, isPlayable: isPlayable),
      MediaKind.image || MediaKind.gif => AppRemoteImage(url: media.url, isConfirmed: isRevealed, fit: fit),
    };
  }
}
