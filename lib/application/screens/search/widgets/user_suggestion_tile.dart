import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/user/app_user_avatar.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ligne d'autocomplétion présentant un utilisateur connu de l'appareil : son icône et son pseudo.
///
/// Conçue pour le fond sombre de l'écran de recherche. L'icône est figée,
/// comme dans toute liste.
class UserSuggestionTile extends ConsumerWidget {
  /// Crée un [UserSuggestionTile].
  ///
  /// - [user] : utilisateur proposé.
  /// - [onTap] : callback déclenché quand l'utilisateur choisit ce profil.
  const UserSuggestionTile({super.key, required this.user, required this.onTap});

  /// Utilisateur proposé.
  final User user;

  /// Callback déclenché quand l'utilisateur choisit ce profil.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorArgb = user.colorArgb;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      // L'icône est dessinée en couleur sombre (`AppGhostText`) : sur le fond
      // sombre de l'écran, on la pose sur une pastille claire pour qu'elle
      // reste lisible.
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: AppUserAvatar(
          avatarText: user.avatarText,
          ghostColor: colorArgb == null ? AppColors.primary : Color(colorArgb),
          fontSize: 13,
          isAnimating: false,
        ),
      ),
      title: Text(
        'u/${user.pseudo}',
        style: const TextStyle(color: AppColors.onDark, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
