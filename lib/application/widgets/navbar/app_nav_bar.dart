import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Données d'un item de la [AppNavBar].
class AppNavBarItem {
  /// Crée un [AppNavBarItem].
  const AppNavBarItem({required this.icon, required this.label});

  /// Icône affichée dans la barre de navigation.
  final IconData icon;

  /// Label sémantique de l'item (pour l'accessibilité).
  final String label;
}

/// Barre de navigation inférieure de l'application.
///
/// Affiche uniquement des icônes. L'item sélectionné reçoit un effet
/// de ghost animé en [AppColors.primary], identique à l'effet du splashscreen.
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

/// Item individuel de la [AppNavBar] avec effet ghost animé si sélectionné.
class _NavBarItemWidget extends ConsumerStatefulWidget {
  /// Crée un [_NavBarItemWidget].
  const _NavBarItemWidget({super.key, required this.item, required this.isSelected, required this.onTap});

  /// Données de l'item.
  final AppNavBarItem item;

  /// Indique si l'item est sélectionné.
  final bool isSelected;

  /// Callback déclenché lors du tap.
  final VoidCallback onTap;

  @override
  ConsumerState<_NavBarItemWidget> createState() => _State();
}

class _State extends ConsumerState<_NavBarItemWidget> with TickerProviderStateMixin {
  /// Contrôleur du pulse (scale) du ghost.
  late final AnimationController _pulseController = AnimationController(
    duration: const Duration(milliseconds: 1_200),
    vsync: this,
  );

  /// Contrôleur du léger tremblement du ghost.
  late final AnimationController _ghostTrembleController = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isSelected) _startAnimations();
  }

  @override
  void didUpdateWidget(_NavBarItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _startAnimations();
      return;
    }

    if (!widget.isSelected && oldWidget.isSelected) {
      _stopAnimations();
      return;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ghostTrembleController.dispose();
    super.dispose();
  }

  /// Démarre les animations en boucle.
  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _ghostTrembleController.repeat(reverse: true);
  }

  /// Arrête les animations et remet les controllers à zéro.
  void _stopAnimations() {
    _pulseController.stop();
    _ghostTrembleController.stop();
    _pulseController.reset();
    _ghostTrembleController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.item.label,
      button: true,
      selected: widget.isSelected,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          height: 56,
          child: Center(child: widget.isSelected ? _buildGhostIcon() : _buildNormalIcon()),
        ),
      ),
    );
  }

  /// Icône sans aucun effet (item non sélectionné).
  Widget _buildNormalIcon() => Icon(widget.item.icon, color: AppColors.disabled, size: 26);

  /// Icône principale statique avec ghost animé (pulse + léger tremblement).
  Widget _buildGhostIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _ghostTrembleController]),
      builder: (context, _) {
        final ghostOffset = Offset(2.8 * _ghostTrembleController.value, 1.8 * _ghostTrembleController.value);

        final iconOffset = Offset(1.5 * _ghostTrembleController.value, 0.6 * _ghostTrembleController.value);

        return SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: ghostOffset,
                child: Icon(widget.item.icon, color: AppColors.primary, size: 26),
              ),
              Transform.translate(
                offset: iconOffset,
                child: Icon(widget.item.icon, color: AppColors.onLight, size: 26),
              ),
            ],
          ),
        );
      },
    );
  }
}
