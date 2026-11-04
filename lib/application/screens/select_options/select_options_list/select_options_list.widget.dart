import 'package:bedbug/application/screens/select_options/select_options_list/select_options_list.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Liste des options d'une `AppSelectBox`, réduite à celles qui correspondent au filtre saisi.
///
/// Seule partie de la page à observer le filtre : la liste se recompose quand il change, le champ de saisie non. Un
/// tap sur une option ferme la page et renvoie sa valeur à l'appelant via `context.pop`.
class SelectOptionsList extends ConsumerWidget {
  /// Crée un [SelectOptionsList].
  ///
  /// - [options] : options proposées, avant filtrage.
  /// - [selectedValue] : valeur actuellement sélectionnée, cochée dans la liste.
  const SelectOptionsList({super.key, required this.options, required this.selectedValue});

  /// Options proposées, avant filtrage.
  final List<AppSelectOption<Object?>> options;

  /// Valeur actuellement sélectionnée, cochée dans la liste.
  final Object? selectedValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(selectOptionsListNotifierProvider);
    final filteredOptions = options.where((option) => option.label.toLowerCase().contains(filter)).toList();
    if (filteredOptions.isEmpty) {
      return Center(child: Text(context.loc.selectNoResult));
    }

    return ListView.separated(
      itemCount: filteredOptions.length,
      separatorBuilder: (context, index) => const AppListSeparator(),
      itemBuilder: (context, index) {
        final option = filteredOptions[index];
        return ListTile(
          title: Text(option.label, style: option.style),
          trailing: option.value == selectedValue ? const AppIcon(AppIcons.check, color: AppColors.primary) : null,
          onTap: () => context.pop(option.value),
        );
      },
    );
  }
}
