import 'package:bedbug/application/screens/content_detail/content_detail_skeleton.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/links/app_external_link.dart';
import 'package:bedbug/application/widgets/links/app_link_preview_image.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur de l'image Open Graph affichée en détail.
const double _ogImageHeight = 160;

/// Page de détail d'un [LinkContent].
class LinkContentDetailScreen extends ConsumerWidget {
  /// Crée un [LinkContentDetailScreen].
  ///
  /// - [content] : contenu lien à afficher en détail.
  const LinkContentDetailScreen({super.key, required this.content});

  /// Contenu lien à afficher en détail.
  final LinkContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentDetailSkeleton(
      contentId: content.id,
      isOwned: content.isOwned,
      title: content.title,
      flair: content.flair,
      signatureId: content.signatureId,
      createdAt: content.createdAt,
      bounce: content.bounce,
      tags: content.tags,
      onClose: () => context.pop(),
      contentBody: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          AppLinkPreviewImage(url: content.ogImageUrl, width: double.infinity, height: _ogImageHeight),
          AppExternalLink(url: content.url, style: AppTextStyles.contentMeta),
          if (content.body != null) Text(content.body!, style: AppTextStyles.contentPreview),
        ],
      ),
    );
  }
}
