import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ligne d'autocomplétion présentant une signature connue de l'appareil : son bedbug et son pseudo.
///
/// Conçue pour le fond sombre de l'écran de recherche. L'icône est figée,
/// comme dans toute liste.
class SignatureSuggestionTile extends ConsumerWidget {
  /// Crée un [SignatureSuggestionTile].
  ///
  /// - [signature] : utilisateur proposé.
  /// - [onTap] : callback déclenché quand l'utilisateur choisit ce profil.
  const SignatureSuggestionTile({super.key, required this.signature, required this.onTap});

  /// Utilisateur proposé.
  final Signature signature;

  /// Callback déclenché quand l'utilisateur choisit ce profil.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorArgb = signature.colorArgb;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      // L'icône est dessinée en couleur sombre (`AppGhostText`) : sur le fond
      // sombre de l'écran, on la pose sur une pastille claire pour qu'elle
      // reste lisible.
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: AppSignatureAvatar(
          avatarText: signature.avatarText,
          ghostColor: colorArgb == null ? AppColors.primary : Color(colorArgb),
          fontSize: 13,
          isAnimating: false,
        ),
      ),
      title: AppPrefixedText(
        prefix: AppPrefixes.signature,
        text: signature.pseudo,
        style: const TextStyle(color: AppColors.onDark, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
