import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/tags/app_tag.widget.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Sélecteur multiple des tags du contenu créé, parmi le catalogue statique [Tag].
///
/// La sélection est portée par le [CreateFormNotifier] : un tap la modifie là-bas, et le sélecteur se reconstruit en
/// l'écoutant.
class TagSelector extends ConsumerWidget {
  /// Crée un [TagSelector].
  const TagSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveValueListenableBuilder<List<Tag>>(
      formControl: ref.read(createFormNotifierProvider.notifier).tagsControl,
      builder: (context, control, child) {
        final selectedTags = control.value ?? const [];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in Tag.values)
              GestureDetector(
                onTap: () => ref.read(createFormNotifierProvider.notifier).toggleTag(tag),
                child: Opacity(
                  opacity: selectedTags.contains(tag) ? 1 : 0.4,
                  child: AppTag(label: tag.text, colors: tag.flutterColors),
                ),
              ),
          ],
        );
      },
    );
  }
}
