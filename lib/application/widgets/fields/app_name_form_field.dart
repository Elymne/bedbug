import 'package:bedbug/application/validators/app_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champ de formulaire reactive pour les noms propres (prénom, nom).
///
/// S'intègre avec [ReactiveForm] via [formControlName]. Interdit la saisie
/// de chiffres en temps réel via un InputFormatter.
///
/// Le [FormControl] associé doit déclarer [AppValidators.required] et
/// [AppValidators.noDigits] pour que les messages d'erreur s'affichent.
class ReactiveAppNameFormField extends StatelessWidget {
  /// Crée un [ReactiveAppNameFormField] avec les paramètres fournis.
  const ReactiveAppNameFormField({
    required this.formControlName,
    required this.labelText,
    required this.requiredErrorText,
    required this.containsDigitsErrorText,
    super.key,
  });

  /// Nom du contrôle dans le [FormGroup] parent.
  final String formControlName;

  /// Libellé affiché dans le champ.
  final String labelText;

  /// Message d'erreur affiché lorsque le champ est vide.
  final String requiredErrorText;

  /// Message d'erreur affiché lorsque la valeur contient des chiffres.
  final String containsDigitsErrorText;

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField<String>(
      formControlName: formControlName,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ\s'\-]"))],
      decoration: InputDecoration(labelText: labelText),
      validationMessages: {'required': (_) => requiredErrorText, 'noDigits': (_) => containsDigitsErrorText},
    );
  }
}
