import 'package:bedbug/application/style/app_colors.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Diamètre d'une pastille de couleur.
const _kSwatchSize = 36.0;

/// Couleurs proposées en un tap, avant de devoir ouvrir le color picker.
const List<Color> _kPresetColors = [
  AppColors.primary,
  AppColors.info,
  AppColors.success,
  AppColors.purple,
  AppColors.orange,
  AppColors.failure,
];

/// Sélecteur de la couleur de profil : quelques pastilles prédéfinies, et une pastille ouvrant un color picker libre.
///
/// Piloté via un [FormControl] passé directement au widget, la couleur
/// n'ayant pas de champ de saisie standard. La pastille libre affiche la
/// couleur choisie dès qu'elle ne fait pas partie des couleurs prédéfinies.
class UserColorSelector extends ConsumerWidget {
  /// Crée un [UserColorSelector].
  ///
  /// - [control] : contrôle portant la couleur sélectionnée.
  const UserColorSelector({super.key, required this.control});

  /// Contrôle portant la couleur sélectionnée.
  final FormControl<Color> control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Color?>(
      stream: control.valueChanges,
      initialData: control.value,
      builder: (context, _) {
        final selectedColor = control.value ?? AppColors.primary;
        final isCustom = !_kPresetColors.contains(selectedColor);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final color in _kPresetColors)
              GestureDetector(
                onTap: () => control.value = color,
                child: _buildSwatch(color: color, isSelected: color == selectedColor),
              ),
            GestureDetector(
              onTap: () => _pickCustomColor(context, selectedColor),
              child: _buildSwatch(
                color: isCustom ? selectedColor : AppColors.surface,
                isSelected: isCustom,
                child: Icon(Icons.colorize, size: 18, color: isCustom ? AppColors.onDark : AppColors.onLight),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Pastille ronde de couleur [color], cerclée quand [isSelected].
  Widget _buildSwatch({required Color color, required bool isSelected, Widget? child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _kSwatchSize,
      height: _kSwatchSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? AppColors.onLight : AppColors.border, width: isSelected ? 3 : 1),
      ),
      child: child,
    );
  }

  /// Ouvre le color picker sur [currentColor] et applique la couleur choisie à [control].
  ///
  /// `showColorPickerDialog` renvoie la couleur de départ en cas
  /// d'annulation : rien ne change alors.
  Future<void> _pickCustomColor(BuildContext context, Color currentColor) async {
    final pickedColor = await showColorPickerDialog(
      context,
      currentColor,
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
      },
      enableShadesSelection: false,
      showColorCode: true,
      colorCodeHasColor: true,
      barrierColor: AppColors.barrier,
      // Material 3 teinte les dialogs avec la couleur primaire (rose) :
      // fond et teinte forcés en blanc.
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
    );
    control.value = pickedColor;
  }
}
