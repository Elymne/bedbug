import 'package:flutter/material.dart';

/// Bouton avec gestion d'état de chargement.
///
/// Affiche [loadingChild] pendant le chargement et désactive le bouton.
/// Affiche [child] dans l'état normal et déclenche [onTap] au clic.
class AppLoadingButton extends StatelessWidget {
  /// Crée un [AppLoadingButton].
  ///
  /// - [isLoading] : si `true`, le bouton est désactivé et affiche [loadingChild].
  /// - [loadingChild] : widget affiché pendant le chargement.
  /// - [child] : widget affiché dans l'état normal.
  /// - [onTap] : appelé au clic quand le bouton n'est pas en chargement.
  /// - [style] : style optionnel appliqué au bouton.
  const AppLoadingButton({
    required this.isLoading,
    required this.loadingChild,
    required this.onTap,
    required this.child,
    this.style,
    super.key,
  });

  /// Indique si le bouton est en état de chargement.
  final bool isLoading;

  /// Widget affiché quand [isLoading] est `true`.
  final Widget loadingChild;

  /// Widget affiché quand [isLoading] est `false`.
  final Widget child;

  /// Appelé au clic quand le bouton n'est pas en chargement.
  final VoidCallback onTap;

  /// Style optionnel du bouton.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: style,
      child: isLoading ? loadingChild : child,
    );
  }
}
