import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Sélecteur multiple des tags parmi le catalogue statique [Tag].
///
/// Ne portant aucune notion de validation, les tags sont pilotés via un
/// [FormControl] passé directement au widget plutôt que via `formControlName`.
class TagSelector extends ConsumerWidget {
  /// Crée un [TagSelector].
  ///
  /// - [control] : contrôle portant la liste des tags actuellement sélectionnés.
  const TagSelector({super.key, required this.control});

  /// Contrôle portant la liste des tags sélectionnés.
  final FormControl<List<Tag>> control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Tag>?>(
      stream: control.valueChanges,
      initialData: control.value,
      builder: (context, _) {
        final selectedTags = control.value ?? const [];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in Tag.values)
              GestureDetector(
                onTap: () => _toggle(tag),
                child: Opacity(
                  opacity: selectedTags.contains(tag) ? 1 : 0.4,
                  child: AppTag(label: tag.text, color: tag.color.flutterColor),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Ajoute ou retire [tag] de la sélection courante et met à jour [control].
  ///
  /// Relit `control.value` au moment de l'appel plutôt que de capturer la
  /// liste affichée au dernier `build` : deux taps rapprochés (avant le
  /// rebuild déclenché par le premier) écraseraient sinon la sélection
  /// précédente au lieu de s'accumuler.
  void _toggle(Tag tag) {
    final selectedTags = control.value ?? const [];
    control.value = selectedTags.contains(tag)
        ? selectedTags.where((selectedTag) => selectedTag != tag).toList()
        : [...selectedTags, tag];
  }
}
