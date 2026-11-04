import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champs de création d'un contenu texte : le titre et le corps.
///
/// Les contrôles sont portés par le [CreateFormNotifier], qui valide et construit le contenu à la publication : ce
/// widget se contente de les afficher.
class TextContentForm extends ConsumerWidget {
  /// Crée un [TextContentForm].
  const TextContentForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      spacing: 16,
      children: [
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: ref.read(createFormNotifierProvider.notifier).textTitleControl,
            textCapitalization: TextCapitalization.sentences,
            validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
            decoration: InputDecoration(labelText: l10n.createTextTitleLabel, hintText: l10n.createTitleHint),
          ),
        ),
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: ref.read(createFormNotifierProvider.notifier).textBodyControl,
            textCapitalization: TextCapitalization.sentences,
            validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
            // Démarre sur une ligne et grandit avec le texte : la barre du bas
            // descend à chaque nouvelle ligne (c'est la page qui défile).
            minLines: 1,
            maxLines: null,
            decoration: InputDecoration(labelText: l10n.createTextBodyLabel, hintText: l10n.createTextBodyHint),
          ),
        ),
      ],
    );
  }
}
