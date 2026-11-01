import 'package:bedbug/application/screens/select_options/select_options_filter_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Page listant les options d'une `AppSelectBox`, avec un champ pour les filtrer.
///
/// Un tap sur une option ferme la page et renvoie sa valeur à l'appelant via
/// `context.pop`. Le retour sans choix renvoie `null`.
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
    final filter = ref.watch(selectOptionsFilterNotifierProvider);
    final options = widget.params.options.where((option) => option.label.toLowerCase().contains(filter)).toList();

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
                    ref.read(selectOptionsFilterNotifierProvider.notifier).updateInput(control.value ?? '');
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: options.isEmpty
                  ? Center(child: Text(l10n.selectNoResult))
                  : ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const AppListSeparator(),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option.value == widget.params.selectedValue;
                        return ListTile(
                          title: Text(option.label, style: option.style),
                          trailing: isSelected ? const AppIcon(AppIcons.check, color: AppColors.primary) : null,
                          onTap: () => context.pop(option.value),
                        );
                      },
                    ),
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
