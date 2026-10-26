import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champs de création d'un contenu lien.
///
/// Les contrôles restent portés par la page de création, qui en a besoin pour
/// valider et construire le contenu à l'enregistrement : ce widget se contente
/// de les afficher.
class LinkContentForm extends ConsumerWidget {
  /// Crée un [LinkContentForm].
  ///
  /// - [titleControl] : contrôle du titre du contenu.
  /// - [urlControl] : contrôle de l'URL partagée.
  const LinkContentForm({super.key, required this.titleControl, required this.urlControl});

  /// Contrôle du titre du contenu.
  final FormControl<String> titleControl;

  /// Contrôle de l'URL partagée.
  final FormControl<String> urlControl;

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
          formControl: urlControl,
          validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.createLinkUrlLabel),
        ),
      ],
    );
  }
}
