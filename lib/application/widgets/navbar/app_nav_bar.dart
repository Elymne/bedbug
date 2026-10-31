import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Données d'un item de la [AppNavBar].
class AppNavBarItem {
  /// Crée un [AppNavBarItem].
  ///
  /// - [icon] : icône affichée dans la barre de navigation.
  /// - [label] : label sémantique de l'item.
  /// - [isGhosting] : `true` pour animer l'icône, afin de signaler une activité en cours.
  const AppNavBarItem({required this.icon, required this.label, this.isGhosting = false});

  /// Icône affichée dans la barre de navigation.
  final IconData icon;

  /// Label sémantique de l'item (pour l'accessibilité).
  final String label;

  /// Indique si l'icône est animée, pour signaler une activité en cours.
  final bool isGhosting;
}

/// Barre de navigation inférieure de l'application.
///
/// Affiche uniquement des icônes. L'item sélectionné est coloré en
/// [AppColors.primary], et un item animé tremble avec un fantôme de cette couleur.
class AppNavBar extends ConsumerWidget {
  /// Crée une [AppNavBar].
  const AppNavBar({super.key, required this.selectedIndex, required this.onTap, required this.items});

  /// Index de l'item actuellement sélectionné.
  final int selectedIndex;

  /// Callback déclenché lors d'un tap sur un item.
  final void Function(int index) onTap;

  /// Liste des items de la barre de navigation.
  final List<AppNavBarItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.disabled, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var index = 0; index < items.length; index++)
                _NavBarItemWidget(
                  key: ValueKey(index),
                  item: items[index],
                  isSelected: index == selectedIndex,
                  onTap: () => onTap(index),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item individuel de la [AppNavBar], coloré en [AppColors.primary] si sélectionné.
class _NavBarItemWidget extends ConsumerWidget {
  /// Crée un [_NavBarItemWidget].
  const _NavBarItemWidget({super.key, required this.item, required this.isSelected, required this.onTap});

  /// Données de l'item.
  final AppNavBarItem item;

  /// Indique si l'item est sélectionné.
  final bool isSelected;

  /// Callback déclenché lors du tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: item.label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          height: 56,
          child: Center(
            child: AppGhostEffect(
              isAnimating: item.isGhosting,
              child: Icon(item.icon, color: isSelected ? AppColors.primary : AppColors.onLight, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
