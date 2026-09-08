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
                onTap: () => _toggle(tag, selectedTags),
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

  /// Ajoute ou retire [tag] de [selectedTags] et met à jour [control].
  void _toggle(Tag tag, List<Tag> selectedTags) {
    control.value = selectedTags.contains(tag)
        ? selectedTags.where((selectedTag) => selectedTag != tag).toList()
        : [...selectedTags, tag];
  }
}
