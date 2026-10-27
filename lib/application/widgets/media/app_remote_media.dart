import 'dart:ui';

import 'package:bedbug/application/notifiers/revealed_urls_notifier.dart';
import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
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

/// Intensité du flou d'un média en greylist.
///
/// Assez pour ne rien reconnaître de choquant, assez peu pour deviner s'il
/// s'agit d'une photo, d'un dessin ou d'une capture.
const double _kBlurSigma = 14;

/// Média distant (image, gif ou vidéo), affiché selon le niveau de confiance de son domaine.
///
/// Seul point d'entrée pour afficher un média venu d'ailleurs : c'est ici
/// que la politique de confiance de l'utilisateur décide de ce qui est
/// chargé.
/// - Domaine de confiance : affiché.
/// - Greylist : chargé mais toujours flouté, sauf dans la visionneuse plein écran ([isGreyRevealed]).
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
  /// - [isGreyRevealed] : `true` pour afficher sans flou un média de la greylist, réservé à la visionneuse plein
  ///   écran, où l'utilisateur a choisi de l'ouvrir (défaut `false`).
  const AppRemoteMedia({
    super.key,
    required this.media,
    this.fit = BoxFit.cover,
    this.isPlayable = false,
    this.isOmittedWhenNotAllowed = false,
    this.isGreyRevealed = false,
  });

  /// Média à afficher.
  final ContentMedia media;

  /// Façon de faire tenir une image dans sa place.
  final BoxFit fit;

  /// Indique si une vidéo peut être lue ici.
  final bool isPlayable;

  /// Indique si rien ne doit être affiché quand le média n'est pas affichable directement.
  final bool isOmittedWhenNotAllowed;

  /// Indique si un média de la greylist est affiché sans flou.
  final bool isGreyRevealed;

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
    if (trust == UrlTrust.grey && !isGreyRevealed) {
      // Pas de geste propre : un tap revient au parent (ouverture du contenu, ou de la visionneuse).
      // Une vidéo n'est pas chargée pour être floutée : seule sa vignette l'est.
      if (media.kind == MediaKind.video) {
        return _blurred(const AppMediaPlaceholder(icon: Icons.play_circle_outline, isDark: true));
      }
      return _blurred(AppRemoteImage(url: media.url, isConfirmed: false, fit: fit));
    }

    return switch (media.kind) {
      MediaKind.video => AppRemoteVideo(url: media.url, isPlayable: isPlayable),
      MediaKind.image || MediaKind.gif => AppRemoteImage(url: media.url, isConfirmed: isRevealed, fit: fit),
    };
  }

  /// Floute [child] et pose dessus l'icône qui signale un média de la greylist.
  ///
  /// - [child] : média à flouter.
  Widget _blurred(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: _kBlurSigma, sigmaY: _kBlurSigma),
            child: child,
          ),
        ),
        const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.barrier, shape: BoxShape.circle),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.visibility_outlined, color: AppColors.onDark),
            ),
          ),
        ),
      ],
    );
  }
}
