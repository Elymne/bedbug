import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.widget.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Durée d'un rebond (montée ou descente) de la flèche.
const Duration _kBounceDuration = Duration(milliseconds: 700);

/// Hauteur du rebond de la flèche.
const double _kBounceHeight = 8;

/// Taille de la flèche.
const double _kArrowSize = 32;

/// Flèche qui rebondit vers le bas, pour désigner l'onglet d'échange de la barre de navigation.
///
/// Le mouvement attire l'œil là où un texte seul passerait inaperçu : l'utilisateur d'un accueil vide va
/// naturellement toucher l'onglet désigné.
class HomeExchangeArrow extends ConsumerStatefulWidget {
  /// Crée un [HomeExchangeArrow].
  const HomeExchangeArrow({super.key});

  @override
  ConsumerState<HomeExchangeArrow> createState() => _State();
}

class _State extends ConsumerState<HomeExchangeArrow> with SingleTickerProviderStateMixin {
  /// Rebond permanent de la flèche, en aller-retour.
  late final _bounceController = AnimationController(vsync: this, duration: _kBounceDuration)..repeat(reverse: true);

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _kBounceHeight * Curves.easeInOut.transform(_bounceController.value)),
          child: child,
        );
      },
      // Noire avec un fantôme rose, comme les icônes animées de la barre de navigation.
      child: const AppGhostEffect(
        isAnimating: true,
        child: AppIcon(AppIcons.arrowDown, color: AppColors.onLightDeep, size: _kArrowSize),
      ),
    );
  }
}
