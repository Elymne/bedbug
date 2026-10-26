import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Largeur maximale de la bulle de texte, en pixels logiques.
///
/// Au-delà, une bulle de 40 caractères passe sur deux lignes plutôt que
/// d'étirer la réaction sur toute la largeur de la page.
const double _bubbleMaxWidth = 160;

/// Une réaction : un bedbug, surmonté de sa bulle de texte quand il y en a une.
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
  /// - [ghostSpeed] : vitesse de l'effet ghost (défaut 1).
  /// - [fontSize] : taille du bedbug (défaut 20).
  /// - [isAnimating] : `false` pour figer le bedbug, par exemple dans une liste (défaut `true`).
  /// - [isMirrored] : `true` pour une réaction alignée à droite : bulle et bedbug calés à droite, coin pincé à droite (défaut `false`).
  const AppReactionBubble({
    super.key,
    required this.avatarText,
    required this.ghostColor,
    this.bubbleText,
    this.ghostSpeed = 1,
    this.fontSize = 20,
    this.isAnimating = true,
    this.isMirrored = false,
  });

  /// Bedbug de la réaction.
  final String avatarText;

  /// Couleur de l'effet ghost.
  final Color ghostColor;

  /// Bulle de texte optionnelle.
  final String? bubbleText;

  /// Vitesse de l'effet ghost.
  final double ghostSpeed;

  /// Taille du bedbug.
  final double fontSize;

  /// Indique si l'effet ghost est animé.
  final bool isAnimating;

  /// Indique si la réaction est alignée à droite, en miroir de la disposition par défaut.
  final bool isMirrored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = bubbleText?.trim() ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: _bubbleMaxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              // Coin inférieur pincé du côté du bedbug : la bulle « sort » de lui.
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomRight: Radius.circular(isMirrored ? 2 : 12),
                bottomLeft: Radius.circular(isMirrored ? 12 : 2),
              ),
            ),
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.onLight)),
          ),
        AppSignatureAvatar(
          avatarText: avatarText,
          ghostColor: ghostColor,
          ghostSpeed: ghostSpeed,
          fontSize: fontSize,
          isAnimating: isAnimating,
        ),
      ],
    );
  }
}
