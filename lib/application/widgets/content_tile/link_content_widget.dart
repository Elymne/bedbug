import 'package:bedbug/application/widgets/content_tile/content_card_widget.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille fixe du thumbnail OG affiché dans la carte.
const double _ogThumbnailSize = 72;

/// Affiche un [LinkContent] sous forme de carte compacte.
///
/// Affiche le thumbnail `og:image` si renseigné dans le contenu.
class LinkContentWidget extends ConsumerWidget {
  /// Crée un [LinkContentWidget].
  ///
  /// - [content] : contenu lien à afficher.
  const LinkContentWidget({super.key, required this.content});

  /// Contenu lien à afficher.
  final LinkContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentCardWidget(
      icon: Icons.link,
      title: content.title,
      preview: content.url,
      trailing: content.ogImageUrl != null ? _buildThumbnail(content.ogImageUrl!) : null,
    );
  }

  /// Construit le thumbnail OG depuis [url].
  Widget _buildThumbnail(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: _ogThumbnailSize,
        height: _ogThumbnailSize,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
