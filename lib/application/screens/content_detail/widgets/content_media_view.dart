import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/media_viewer/media_viewer_screen.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/content/domain/services/url_trust_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur des médias, en fraction de la hauteur de l'écran.
///
/// Les proportions d'un média distant ne sont connues qu'une fois chargé :
/// une hauteur fixe évite que la page saute au chargement.
const double _kHeightFactor = 0.5;

/// Rayon des coins arrondis des médias.
const double _kRadius = 8;

/// Médias d'un contenu sur sa page de détail, en entier, sans recadrage.
///
/// Plusieurs médias sont présentés dans un carrousel horizontal, avec leur
/// position. Un tap ouvre la visionneuse plein écran, seul endroit où un
/// média de la greylist est défloué. Seule exception : une vidéo d'un
/// domaine de confiance se lit sur place, sans passer par la visionneuse.
class ContentMediaView extends ConsumerWidget {
  /// Crée un [ContentMediaView].
  ///
  /// - [media] : médias du contenu, dans l'ordre d'affichage.
  const ContentMediaView({super.key, required this.media});

  /// Médias du contenu, dans l'ordre d'affichage.
  final List<ContentMedia> media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustSettingsNotifierWatcher = ref.watch(trustSettingsNotifierProvider);
    final mediaPolicy = trustSettingsNotifierWatcher.value?.mediaPolicy;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * _kHeightFactor,
      child: PageView(
        children: [
          for (final (index, item) in media.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: _isPlayedInline(ref, item, mediaPolicy) ? null : () => _openViewer(context, index),
                      child: AppRemoteMedia(media: item, fit: BoxFit.contain, isPlayable: true),
                    ),
                    if (media.length > 1)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: AppImageCountBadge(label: '${index + 1}/${media.length}'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Indique si [item] se lit sur place : une vidéo dont le domaine n'est pas en greylist.
  ///
  /// Une vidéo en greylist n'est qu'une vignette floutée : elle se lit dans
  /// la visionneuse. Celle d'un domaine inconnu gère elle-même son tap
  /// (confirmation), puis se lit sur place une fois dévoilée.
  ///
  /// - [ref] : accès au service de confiance.
  /// - [item] : média touché.
  /// - [mediaPolicy] : politique de confiance des médias, `null` tant qu'elle n'est pas chargée.
  bool _isPlayedInline(WidgetRef ref, ContentMedia item, UrlTrustPolicy? mediaPolicy) {
    if (item.kind != MediaKind.video) {
      return false;
    }
    if (mediaPolicy == null) {
      return true;
    }
    return ref.read(urlTrustServiceProvider).evaluate(mediaPolicy, item.url) != UrlTrust.grey;
  }

  /// Ouvre la visionneuse plein écran sur les médias du contenu, à partir de celui en position [index].
  ///
  /// - [context] : contexte depuis lequel naviguer.
  /// - [index] : position du média touché.
  void _openViewer(BuildContext context, int index) {
    context.push(
      mediaViewerPath,
      extra: MediaViewerParams(media: media, initialIndex: index),
    );
  }
}
