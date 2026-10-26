import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champs de création d'un contenu texte.
///
/// Les contrôles restent portés par la page de création, qui en a besoin pour
/// valider et construire le contenu à l'enregistrement : ce widget se contente
/// de les afficher.
class TextContentForm extends ConsumerWidget {
  /// Crée un [TextContentForm].
  ///
  /// - [titleControl] : contrôle du titre du contenu.
  /// - [bodyControl] : contrôle du corps du contenu.
  const TextContentForm({super.key, required this.titleControl, required this.bodyControl});

  /// Contrôle du titre du contenu.
  final FormControl<String> titleControl;

  /// Contrôle du corps du contenu.
  final FormControl<String> bodyControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      spacing: 16,
      children: [
        ReactiveTextField<String>(
          formControl: titleControl,
          textCapitalization: TextCapitalization.sentences,
          validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
          decoration: InputDecoration(labelText: l10n.createTextTitleLabel),
        ),
        ReactiveTextField<String>(
          formControl: bodyControl,
          textCapitalization: TextCapitalization.sentences,
          validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
          // Démarre sur une ligne et grandit avec le texte : la barre du bas
          // descend à chaque nouvelle ligne (c'est la page qui défile).
          minLines: 1,
          maxLines: null,
          decoration: InputDecoration(labelText: l10n.createTextBodyLabel),
        ),
      ],
    );
  }
}
