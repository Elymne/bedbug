import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hauteur de l'aperçu du premier média, en fraction de la hauteur de l'écran.
const double _kPreviewHeightFactor = 0.3;

/// Rayon des coins arrondis de l'aperçu.
const double _kPreviewRadius = 8;

/// Affiche un [MediaContent] sous forme de tuile compacte.
///
/// Affiche le titre (2 lignes max) puis le premier média en dessous, dans
/// une hauteur fixe pour que le fil ne saute pas au chargement des images.
/// Une vidéo n'y est qu'une vignette : elle se lit depuis la page de détail.
/// Quand le contenu regroupe plusieurs médias, un badge indique leur nombre.
class MediaContentWidget extends ConsumerWidget {
  /// Crée un [MediaContentWidget].
  ///
  /// - [content] : contenu média à afficher.
  const MediaContentWidget({super.key, required this.content});

  /// Contenu média à afficher.
  final MediaContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(content.title, style: AppTextStyles.contentTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ClipRRect(
          borderRadius: BorderRadius.circular(_kPreviewRadius),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * _kPreviewHeightFactor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppRemoteMedia(media: content.media.first),
                if (content.media.length > 1)
                  PositionedDirectional(top: 8, end: 8, child: AppImageCountBadge(label: '${content.media.length}')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
