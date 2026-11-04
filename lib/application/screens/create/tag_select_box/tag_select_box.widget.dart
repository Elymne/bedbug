import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/tags/app_tag.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champ des tags du contenu créé : affiche les tags choisis et ouvre la page du catalogue pour les modifier.
///
/// Le formulaire ne garde qu'un résumé de la sélection : le choix lui-même se fait sur une page dédiée, qui laisse la
/// place à un catalogue qui grandit. La sélection est portée par le [CreateFormNotifier], et le champ se reconstruit
/// en l'écoutant.
class TagSelectBox extends ConsumerWidget {
  /// Crée un [TagSelectBox].
  const TagSelectBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return ReactiveValueListenableBuilder<List<Tag>>(
      formControl: ref.read(createFormNotifierProvider.notifier).tagsControl,
      builder: (context, control, child) {
        final selectedTags = control.value ?? const [];
        return InkWell(
          borderRadius: BorderRadius.circular(AppValues.fieldRadius),
          onTap: () => _openTagPicker(context, control),
          child: InputDecorator(
            isEmpty: selectedTags.isEmpty,
            decoration: InputDecoration(
              labelText: l10n.createTagsLabel,
              hintText: l10n.createTagsHint,
              suffixIcon: const AppIcon(AppIcons.expandMore, color: AppColors.onLight),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in selectedTags) AppTag(label: tag.text, colors: tag.flutterColors)],
            ),
          ),
        );
      },
    );
  }

  /// Ouvre la page du catalogue et applique la sélection qu'elle renvoie.
  ///
  /// - [context] : contexte depuis lequel ouvrir la page.
  /// - [control] : contrôle des tags sélectionnés, mis à jour au retour.
  Future<void> _openTagPicker(BuildContext context, AbstractControl<List<Tag>> control) async {
    final selectedTags = await context.push<List<Tag>>(tagPickerPath, extra: control.value ?? const <Tag>[]);
    if (selectedTags == null) {
      return;
    }
    control.value = selectedTags;
  }
}
