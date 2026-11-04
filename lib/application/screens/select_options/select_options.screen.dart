import 'package:bedbug/application/screens/select_options/select_options_list/select_options_list.notifier.dart';
import 'package:bedbug/application/screens/select_options/select_options_list/select_options_list.widget.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Page listant les options d'une `AppSelectBox`, avec un champ pour les filtrer.
///
/// Un tap sur une option ferme la page et renvoie sa valeur à l'appelant via
/// `context.pop`. Le retour sans choix renvoie `null`.
///
/// Page statique : elle porte le champ de filtrage, et la liste observe elle-même le filtre appliqué.
class SelectOptionsScreen extends ConsumerStatefulWidget {
  /// Crée un [SelectOptionsScreen].
  ///
  /// - [params] : libellé, options et valeur sélectionnée à afficher.
  const SelectOptionsScreen({super.key, required this.params});

  /// Libellé, options et valeur sélectionnée à afficher.
  final SelectOptionsParams params;

  @override
  ConsumerState<SelectOptionsScreen> createState() => _State();
}

class _State extends ConsumerState<SelectOptionsScreen> {
  /// Contrôle du texte de filtrage.
  late final _filterControl = FormControl<String>();

  /// Formulaire du filtrage.
  late final FormGroup _form = FormGroup({'filter': _filterControl});

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: widget.params.label, onBack: context.pop),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: AppFieldFocusPulse(
                child: ReactiveTextField<String>(
                  formControl: _filterControl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(hintText: l10n.selectFilterHint),
                  onChanged: (control) {
                    ref.read(selectOptionsListNotifierProvider.notifier).updateInput(control.value ?? '');
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SelectOptionsList(options: widget.params.options, selectedValue: widget.params.selectedValue),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paramètres de la page [SelectOptionsScreen].
class SelectOptionsParams {
  /// Crée des [SelectOptionsParams].
  ///
  /// - [label] : libellé de l'`AppSelectBox`, affiché en titre.
  /// - [options] : options proposées.
  /// - [selectedValue] : valeur actuellement sélectionnée.
  const SelectOptionsParams({required this.label, required this.options, required this.selectedValue});

  /// Libellé de l'`AppSelectBox`, affiché en titre.
  final String label;

  /// Options proposées.
  final List<AppSelectOption<Object?>> options;

  /// Valeur actuellement sélectionnée.
  final Object? selectedValue;
}
