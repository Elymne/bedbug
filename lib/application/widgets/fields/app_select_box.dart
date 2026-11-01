import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/select_options/select_options_screen.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champ de sélection : affiche l'option choisie et ouvre une page listant toutes les options.
///
/// Une page plutôt qu'un menu déroulant : elle laisse la place à une longue
/// liste et à son filtrage. Revenir sans choisir laisse la valeur en place.
///
/// Piloté via un [FormControl] passé directement au widget, comme les autres
/// champs sans saisie standard.
class AppSelectBox<T> extends ConsumerWidget {
  /// Crée une [AppSelectBox].
  ///
  /// - [control] : contrôle portant la valeur sélectionnée.
  /// - [label] : libellé du champ, repris en titre de la page des options.
  /// - [options] : options proposées.
  /// - [hintText] : texte affiché tant qu'aucune option n'est choisie.
  /// - [onSelected] : appelé avec la valeur choisie, une fois [control] mis à jour.
  const AppSelectBox({
    super.key,
    required this.control,
    required this.label,
    required this.options,
    this.hintText,
    this.onSelected,
  });

  /// Contrôle portant la valeur sélectionnée.
  final FormControl<T> control;

  /// Libellé du champ, repris en titre de la page des options.
  final String label;

  /// Options proposées.
  final List<AppSelectOption<T>> options;

  /// Texte affiché tant qu'aucune option n'est choisie.
  final String? hintText;

  /// Appelé avec la valeur choisie, une fois [control] mis à jour.
  ///
  /// Sert aux parcours dont le choix n'est que la première étape.
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<T?>(
      stream: control.valueChanges,
      initialData: control.value,
      builder: (context, _) {
        final selectedOptions = options.where((option) => option.value == control.value);
        final selectedOption = selectedOptions.isEmpty ? null : selectedOptions.first;

        return InkWell(
          borderRadius: BorderRadius.circular(AppValues.fieldRadius),
          onTap: () => _openOptions(context),
          child: InputDecorator(
            isEmpty: selectedOption == null,
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              suffixIcon: const AppIcon(AppIcons.expandMore, color: AppColors.onLight),
            ),
            child: Text(selectedOption?.label ?? '', style: selectedOption?.style),
          ),
        );
      },
    );
  }

  /// Ouvre la page des options et applique celle qui est choisie.
  ///
  /// - [context] : contexte depuis lequel ouvrir la page.
  Future<void> _openOptions(BuildContext context) async {
    final value = await context.push<T>(
      selectOptionsPath,
      extra: SelectOptionsParams(label: label, options: options, selectedValue: control.value),
    );
    if (value == null) {
      return;
    }
    control.value = value;
    onSelected?.call(value);
  }
}
