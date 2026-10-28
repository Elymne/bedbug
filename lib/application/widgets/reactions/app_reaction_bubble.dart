import 'package:bedbug/application/widgets/ghost/app_ghost_animation.dart';
import 'package:bedbug/application/widgets/reactions/reaction_bubble_layer.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Style de rendu des réactions dans toute l'application.
///
/// Point unique pour comparer les rendus : changer cette valeur suffit.
const ReactionBubbleStyle appReactionBubbleStyle = ReactionBubbleStyle.backed;

/// Une réaction : un bedbug, surmonté de sa bulle de texte quand il y en a une, le tout animé d'un effet ghost.
///
/// La bulle fait partie de l'animation : elle tremble avec le bedbug, dans
/// la couleur et l'intensité de la réaction. La façon d'empiler la couleur
/// ghost avec le fond, le texte et le contour dépend de [style].
///
/// Purement visuel : utilisé dans la liste des réactions d'un contenu comme
/// dans l'aperçu du formulaire de réaction, pour que l'utilisateur voie
/// exactement ce qui sera affiché.
class AppReactionBubble extends ConsumerWidget {
  /// Crée un [AppReactionBubble].
  ///
  /// - [avatarText] : bedbug de la réaction.
  /// - [ghostColor] : couleur de l'effet ghost, choisie pour la réaction.
  /// - [bubbleText] : bulle de texte optionnelle, masquée si `null` ou vide.
  /// - [bubbleFont] : police de la bulle de texte (défaut [TextFont.standard]).
  /// - [ghostSpeed] : vitesse de l'effet ghost (défaut 1).
  /// - [fontSize] : taille du bedbug (défaut 20).
  /// - [isAnimating] : `false` pour figer le bedbug, par exemple dans une liste (défaut `true`).
  /// - [isMirrored] : `true` pour une réaction alignée à droite : bulle et bedbug calés à droite, coin pincé à droite (défaut `false`).
  /// - [style] : façon d'empiler les couches de la réaction (défaut [appReactionBubbleStyle]).
  const AppReactionBubble({
    super.key,
    required this.avatarText,
    required this.ghostColor,
    this.bubbleText,
    this.bubbleFont = TextFont.standard,
    this.ghostSpeed = 1,
    this.fontSize = 20,
    this.isAnimating = true,
    this.isMirrored = false,
    this.style = appReactionBubbleStyle,
  });

  /// Bedbug de la réaction.
  final String avatarText;

  /// Couleur de l'effet ghost.
  final Color ghostColor;

  /// Bulle de texte optionnelle.
  final String? bubbleText;

  /// Police de la bulle de texte.
  final TextFont bubbleFont;

  /// Vitesse de l'effet ghost.
  final double ghostSpeed;

  /// Taille du bedbug.
  final double fontSize;

  /// Indique si l'effet ghost est animé.
  final bool isAnimating;

  /// Indique si la réaction est alignée à droite, en miroir de la disposition par défaut.
  final bool isMirrored;

  /// Façon d'empiler les couches de la réaction.
  final ReactionBubbleStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGhostAnimation(
      isAnimating: isAnimating,
      speed: ghostSpeed,
      // L'amplitude suit la taille du bedbug, comme pour une signature.
      intensity: fontSize / 32,
      builder: (context, offsets) {
        if (offsets == null) {
          return _layer(hasFill: style != ReactionBubbleStyle.outline, hasBorder: true, hasText: true);
        }
        // Chaque liste va du fond vers l'avant.
        return Stack(
          clipBehavior: Clip.none,
          children: switch (style) {
            ReactionBubbleStyle.outline => [
              _ghostLayer(offsets),
              _mainLayer(offsets, hasFill: false, hasBorder: true, hasText: true),
            ],
            ReactionBubbleStyle.backed => [
              _mainLayer(offsets, hasFill: true, hasBorder: false, hasText: false),
              _ghostLayer(offsets),
              _mainLayer(offsets, hasFill: false, hasBorder: true, hasText: true),
            ],
            ReactionBubbleStyle.layered => [
              _mainLayer(offsets, hasFill: true, hasBorder: false, hasText: false),
              _mainLayer(offsets, hasFill: false, hasBorder: false, hasText: true),
              _ghostLayer(offsets),
              _mainLayer(offsets, hasFill: false, hasBorder: true, hasText: false),
            ],
          },
        );
      },
    );
  }

  /// Calque coloré de l'effet ghost : la silhouette du contour, du texte et du bedbug, au décalage ghost.
  ///
  /// - [offsets] : décalages courants de l'animation.
  Widget _ghostLayer(GhostOffsets offsets) {
    return Transform.translate(
      offset: offsets.ghost,
      // `srcIn` ne garde que la forme du calque, remplie de la couleur ghost.
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(ghostColor, BlendMode.srcIn),
        child: _layer(hasFill: false, hasBorder: true, hasText: true),
      ),
    );
  }

  /// Calque qui suit le tremblement principal, dont seules les parties demandées sont visibles.
  ///
  /// - [offsets] : décalages courants de l'animation.
  /// - [hasFill] : `true` pour dessiner le fond blanc de la bulle.
  /// - [hasBorder] : `true` pour dessiner le contour de la bulle.
  /// - [hasText] : `true` pour dessiner le texte de la bulle et le bedbug.
  Widget _mainLayer(GhostOffsets offsets, {required bool hasFill, required bool hasBorder, required bool hasText}) {
    return Transform.translate(
      offset: offsets.main,
      child: _layer(hasFill: hasFill, hasBorder: hasBorder, hasText: hasText),
    );
  }

  /// Calque de cette réaction dont seules les parties demandées sont visibles.
  ///
  /// - [hasFill] : `true` pour dessiner le fond blanc de la bulle.
  /// - [hasBorder] : `true` pour dessiner le contour de la bulle.
  /// - [hasText] : `true` pour dessiner le texte de la bulle et le bedbug.
  Widget _layer({required bool hasFill, required bool hasBorder, required bool hasText}) {
    return ReactionBubbleLayer(
      avatarText: avatarText,
      bubbleText: bubbleText?.trim() ?? '',
      bubbleFont: bubbleFont,
      fontSize: fontSize,
      isMirrored: isMirrored,
      hasFill: hasFill,
      hasBorder: hasBorder,
      hasText: hasText,
    );
  }
}

/// Façon d'empiler les couches d'une réaction.
enum ReactionBubbleStyle {
  /// Bulle sans fond, réduite à son contour : la couleur ghost dédouble le contour, le texte et le bedbug.
  outline,

  /// Comme [outline], avec un fond blanc tout au fond, derrière la couleur ghost, le texte et le contour.
  backed,

  /// Couches séparées, de l'avant vers le fond : contour noir, couleur ghost, texte, fond blanc.
  layered,
}
