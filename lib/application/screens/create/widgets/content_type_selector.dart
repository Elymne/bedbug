import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_icon.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icône associée à chaque [ContentType].
const _kTypeIcons = {
  ContentType.text: Icons.notes,
  ContentType.image: Icons.image_outlined,
  ContentType.link: Icons.link,
};

/// Sélecteur de type de contenu affiché sous forme d'icônes toggleables.
class ContentTypeSelector extends ConsumerWidget {
  /// Crée un [ContentTypeSelector].
  ///
  /// - [selectedType] : type actuellement sélectionné.
  /// - [isLocked] : `true` si le type ne peut plus être changé.
  /// - [onTypeSelected] : callback déclenché lors du tap sur un type non désactivé.
  const ContentTypeSelector({
    super.key,
    required this.selectedType,
    required this.isLocked,
    required this.onTypeSelected,
  });

  /// Type de contenu actuellement sélectionné.
  final ContentType selectedType;

  /// Indique si le changement de type est verrouillé.
  final bool isLocked;

  /// Callback déclenché lors de la sélection d'un type.
  final void Function(ContentType) onTypeSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      spacing: 4,
      children: [
        for (final type in ContentType.values)
          _TypeIconButton(
            icon: _kTypeIcons[type]!,
            isSelected: type == selectedType,
            isDisabled: isLocked && type != selectedType,
            onTap: () => onTypeSelected(type),
          ),
      ],
    );
  }
}

/// Bouton icône individuel du [ContentTypeSelector].
class _TypeIconButton extends ConsumerWidget {
  /// Crée un [_TypeIconButton].
  ///
  /// - [icon] : icône affichée.
  /// - [isSelected] : `true` si ce type est sélectionné.
  /// - [isDisabled] : `true` si ce type est verrouillé et non sélectionnable.
  /// - [onTap] : callback déclenché au tap si non désactivé.
  const _TypeIconButton({required this.icon, required this.isSelected, required this.isDisabled, required this.onTap});

  /// Icône affichée.
  final IconData icon;

  /// Indique si ce bouton est sélectionné.
  final bool isSelected;

  /// Indique si ce bouton est désactivé.
  final bool isDisabled;

  /// Callback déclenché au tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: isSelected
            ? AppGhostIcon(icon: icon, size: 24, isAnimating: true, speed: 1.4, intensity: 2)
            : Icon(icon, size: 24, color: isDisabled ? AppColors.disabled : AppColors.onLight),
      ),
    );
  }
}
