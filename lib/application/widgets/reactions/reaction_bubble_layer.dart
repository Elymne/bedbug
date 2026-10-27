import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/text_font_x.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Largeur maximale de la bulle de texte, en pixels logiques.
///
/// Au-delà, une bulle de 40 caractères passe sur deux lignes plutôt que
/// d'étirer la réaction sur toute la largeur de la page.
const double _kBubbleMaxWidth = 160;

/// Un calque d'une réaction : le bedbug et sa bulle, dont seules certaines parties sont visibles.
///
/// Une réaction peut être dessinée en plusieurs calques empilés (fond, texte,
/// couleur ghost, contour). Chaque calque garde exactement la même mise en
/// page : les parties masquées sont dessinées en transparent plutôt que
/// retirées, pour que les calques se superposent au pixel près.
class ReactionBubbleLayer extends ConsumerWidget {
  /// Crée un [ReactionBubbleLayer].
  ///
  /// - [avatarText] : bedbug de la réaction.
  /// - [bubbleText] : texte de la bulle, bulle absente si vide.
  /// - [bubbleFont] : police du texte de la bulle.
  /// - [fontSize] : taille du bedbug.
  /// - [isMirrored] : `true` pour caler le calque à droite, coin de la bulle pincé à droite.
  /// - [hasFill] : `true` pour dessiner le fond blanc de la bulle.
  /// - [hasBorder] : `true` pour dessiner le contour de la bulle.
  /// - [hasText] : `true` pour dessiner le texte de la bulle et le bedbug.
  const ReactionBubbleLayer({
    super.key,
    required this.avatarText,
    required this.bubbleText,
    required this.bubbleFont,
    required this.fontSize,
    required this.isMirrored,
    required this.hasFill,
    required this.hasBorder,
    required this.hasText,
  });

  /// Bedbug de la réaction.
  final String avatarText;

  /// Texte de la bulle, bulle absente si vide.
  final String bubbleText;

  /// Police du texte de la bulle.
  final TextFont bubbleFont;

  /// Taille du bedbug.
  final double fontSize;

  /// Indique si le calque est calé à droite, coin de la bulle pincé à droite.
  final bool isMirrored;

  /// Indique si le fond blanc de la bulle est dessiné.
  final bool hasFill;

  /// Indique si le contour de la bulle est dessiné.
  final bool hasBorder;

  /// Indique si le texte de la bulle et le bedbug sont dessinés.
  final bool hasText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = hasText ? AppColors.onLight : Colors.transparent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (bubbleText.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: _kBubbleMaxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasFill ? AppColors.surface : Colors.transparent,
              // Toujours une bordure, transparente si masquée : sa largeur fait partie de la mise en page.
              border: Border.all(color: hasBorder ? AppColors.onLight : Colors.transparent),
              // Coin inférieur pincé du côté du bedbug : la bulle « sort » de lui.
              // Directionnel : le bedbug est calé au début de la ligne, à
              // droite dans une langue écrite de droite à gauche.
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(12),
                topEnd: const Radius.circular(12),
                bottomEnd: Radius.circular(isMirrored ? 2 : 12),
                bottomStart: Radius.circular(isMirrored ? 12 : 2),
              ),
            ),
            child: Text(bubbleText, style: bubbleFont.apply(TextStyle(fontSize: 12, color: textColor))),
          ),
        Text(
          avatarText,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: textColor),
        ),
      ],
    );
  }
}
