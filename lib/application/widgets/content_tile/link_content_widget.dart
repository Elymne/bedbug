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
/// Structure : titre utilisateur + ogTitle en dessous, ogImage à droite.
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(content.title, style: AppTextStyles.contentTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (content.ogTitle != null)
                    Text(
                      content.ogTitle!,
                      style: AppTextStyles.contentPreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            AppNetworkImage(url: content.ogImageUrl, width: imageWidth, height: _ogImageHeight),
          ],
        );
      },
    );
  }
}
