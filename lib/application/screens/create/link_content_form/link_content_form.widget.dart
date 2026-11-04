import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champs de création d'un contenu lien : le titre et l'URL partagée.
///
/// Les contrôles sont portés par le [CreateFormNotifier], qui valide et construit le contenu à la publication : ce
/// widget se contente de les afficher.
class LinkContentForm extends ConsumerWidget {
  /// Crée un [LinkContentForm].
  const LinkContentForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      spacing: 16,
      children: [
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: ref.read(createFormNotifierProvider.notifier).linkTitleControl,
            textCapitalization: TextCapitalization.sentences,
            validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
            decoration: InputDecoration(labelText: l10n.createTextTitleLabel, hintText: l10n.createTitleHint),
          ),
        ),
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: ref.read(createFormNotifierProvider.notifier).linkUrlControl,
            validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: l10n.createLinkUrlLabel, hintText: l10n.createLinkUrlHint),
          ),
        ),
      ],
    );
  }
}
