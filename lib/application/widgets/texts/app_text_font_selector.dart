import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/text_font_x.dart';
import 'package:bedbug/application/widgets/fields/app_select_box.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Sélecteur de la police d'un texte court, dont chaque nom est écrit dans la police elle-même.
///
/// Sert pour la bulle d'une réaction comme pour la description d'une
/// signature. Écrire chaque nom dans sa police permet de choisir d'un coup
/// d'œil, sans avoir à tester chaque police dans l'aperçu.
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

    return AppSelectBox<TextFont>(
      control: control,
      label: l10n.textFontLabel,
      options: [
        for (final font in TextFont.values)
          AppSelectOption(
            value: font,
            label: font.displayName ?? l10n.textFontStandard,
            style: font.apply(const TextStyle(fontSize: 16, color: AppColors.onLight)),
          ),
      ],
    );
  }
}
