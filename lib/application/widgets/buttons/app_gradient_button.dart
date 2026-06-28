import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton générique avec fond en dégradé et coins arrondis.
///
/// Affiche [child] en état normal. Quand [isLoading] est `true`,
/// le bouton est désactivé et affiche un [CircularProgressIndicator].
class AppGradientButton extends ConsumerWidget {
  /// Crée un [AppGradientButton].
  ///
  /// - [child] : contenu affiché dans le bouton.
  /// - [onTap] : callback déclenché au tap. `null` désactive le bouton.
  /// - [isLoading] : `true` pour afficher le loader et désactiver le tap.
  const AppGradientButton({
    super.key,
    required this.child,
    required this.onTap,
    this.isLoading = false,
  });

  /// Contenu affiché dans le bouton.
  final Widget child;

  /// Callback déclenché au tap.
  final VoidCallback? onTap;

  /// Indique si le bouton est en état de chargement.
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDisabled = isLoading || onTap == null;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.onLight, AppColors.onLightDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onDark,
                  ),
                )
              : DefaultTextStyle(
                  style: const TextStyle(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  child: child,
                ),
        ),
      ),
    );
  }
}
