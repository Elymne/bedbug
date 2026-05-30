import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/images/app_network_image.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Espacement horizontal entre le bloc texte et l'image OG.
const double _iconSpacing = 16;

/// Hauteur fixe de la zone image OG.
const double _ogImageHeight = 80.0;

/// Affiche un [LinkContent] sous forme de tuile compacte.
///
/// Affiche le thumbnail `og:image` à droite sur 30% de la largeur.
class LinkContentWidget extends ConsumerWidget {
  /// Crée un [LinkContentWidget].
  ///
  /// - [content] : contenu lien à afficher.
  const LinkContentWidget({super.key, required this.content});

  /// Contenu lien à afficher.
  final LinkContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 0.3;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _iconSpacing,
          children: [
            Expanded(
              child: Text(
                content.ogTitle ?? content.url,
                style: AppTextStyles.contentTitle,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppNetworkImage(url: content.ogImageUrl, width: imageWidth, height: _ogImageHeight),
          ],
        );
      },
    );
  }
}
