import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_const.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agrandissement maximal du texte des items, pour qu'il tienne dans la barre même avec un grand texte système.
const double _kMaxLabelScale = 1.2;

/// Données d'un item de la [AppNavBar].
class AppNavBarItem {
  /// Crée un [AppNavBarItem].
  ///
  /// - [icon] : icône affichée dans la barre de navigation.
  /// - [label] : texte affiché sous l'icône.
  /// - [isGhosting] : `true` pour animer l'icône, afin de signaler une activité en cours.
  const AppNavBarItem({required this.icon, required this.label, this.isGhosting = false});

  /// Icône affichée dans la barre de navigation.
  final AppIcons icon;

  /// Texte affiché sous l'icône.
  final String label;

  /// Indique si l'icône est animée, pour signaler une activité en cours.
  final bool isGhosting;
}

/// Barre de navigation inférieure de l'application.
///
/// Chaque item affiche une icône et son texte, sur une largeur égale. L'item
/// sélectionné est coloré en [AppColors.primary], et un item animé tremble avec
/// un fantôme de cette couleur.
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
          height: AppConst.homeNavBarBaseHeight,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _NavBarItemWidget(
                    key: ValueKey(index),
                    item: items[index],
                    isSelected: index == selectedIndex,
                    onTap: () => onTap(index),
                  ),
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
    final color = isSelected ? AppColors.primary : AppColors.onLight;

    return Semantics(
      label: item.label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // Le label porté par `Semantics` suffit : le texte visible serait lu une seconde fois.
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              AppGhostEffect(
                isAnimating: item.isGhosting,
                child: AppIcon(item.icon, color: color, size: 26),
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _kMaxLabelScale),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
