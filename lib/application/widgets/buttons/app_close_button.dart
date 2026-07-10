import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton de fermeture avec une icône croix, à placer en haut à gauche d'une vue modale.
class AppCloseButton extends ConsumerWidget {
  /// Crée un [AppCloseButton].
  ///
  /// - [onTap] : callback déclenché lors du tap. Si `null`, utilise [Navigator.pop].
  const AppCloseButton({super.key, this.onTap});

  /// Callback déclenché lors du tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: onTap ?? () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close, color: AppColors.onLight),
    );
  }
}
