import 'package:bedbug/application/notifiers/content_author.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.widget.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.widget.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Signature de l'auteur d'un contenu sur sa page de détail : `s/pseudo` suivi de son bedbug.
///
/// Un tap ouvre la page de la signature, sauf pour l'anonyme, commun à tous les auteurs anonymes. Le temps de charger
/// le profil, l'auteur est présenté comme anonyme : la ligne garde sa place au lieu d'apparaître après coup.
class ContentDetailAuthor extends ConsumerWidget {
  /// Crée un [ContentDetailAuthor].
  ///
  /// - [signatureId] : identifiant de la signature de l'auteur.
  const ContentDetailAuthor({super.key, required this.signatureId});

  /// Identifiant de la signature de l'auteur.
  final String signatureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(signatureId));
    final author = contentAuthorNotifierWatcher.value ?? anonymousSignature;
    final authorColorArgb = author.colorArgb;

    return GestureDetector(
      onTap: signatureId == anonymousSignatureId
          ? null
          : () => context.push('$signaturesPath/${Uri.encodeComponent(signatureId)}'),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          AppPrefixedText(prefix: signaturePrefix, text: author.pseudo, style: AppTextStyles.contentMeta),
          // Le bedbug de l'auteur, à droite de son pseudo.
          AppSignatureAvatar(
            avatarText: author.avatarText,
            ghostColor: authorColorArgb == null ? AppColors.primary : Color(authorColorArgb),
            ghostSpeed: author.ghostSpeed,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}
