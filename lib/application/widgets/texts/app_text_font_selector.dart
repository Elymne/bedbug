import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/text_font_x.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Sélecteur de la police d'un texte court : une pastille par [TextFont], dont le nom est écrit dans la police elle-même.
///
/// Sert pour la bulle d'une réaction comme pour la description d'une
/// signature. Écrire chaque nom dans sa police permet de choisir d'un coup
/// d'œil, sans avoir à tester chaque police dans l'aperçu.
///
/// Piloté via un [FormControl] passé directement au widget, la police
/// n'ayant pas de champ de saisie standard.
class AppTextFontSelector extends ConsumerWidget {
  /// Crée un [AppTextFontSelector].
  ///
  /// - [control] : contrôle portant la police sélectionnée.
  const AppTextFontSelector({super.key, required this.control});

  /// Contrôle portant la police sélectionnée.
  final FormControl<TextFont> control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return StreamBuilder<TextFont?>(
      stream: control.valueChanges,
      initialData: control.value,
      builder: (context, _) {
        final selectedFont = control.value ?? TextFont.standard;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final font in TextFont.values)
              ChoiceChip(
                label: Text(
                  font.displayName ?? l10n.textFontStandard,
                  style: font.apply(const TextStyle(fontSize: 14, color: AppColors.onLight)),
                ),
                selected: font == selectedFont,
                showCheckmark: false,
                selectedColor: AppColors.surface,
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: font == selectedFont ? AppColors.onLight : AppColors.border,
                  width: font == selectedFont ? 2 : 1,
                ),
                onSelected: (_) => control.value = font,
              ),
          ],
        );
      },
    );
  }
}
