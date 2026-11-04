import 'package:bedbug/application/validators/no_digits.validator.dart';
import 'package:bedbug/application/validators/not_empty.validator.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champ de formulaire reactive pour les noms propres (prénom, nom).
///
/// S'intègre avec [ReactiveForm] via [formControlName]. Interdit la saisie
/// de chiffres en temps réel via un InputFormatter.
///
/// Le [FormControl] associé doit déclarer [NotEmptyValidator] et
/// [NoDigitsValidator] pour que les messages d'erreur s'affichent.
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
    return AppFieldFocusPulse(
      child: ReactiveTextField<String>(
        formControlName: formControlName,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ\s'\-]"))],
        decoration: InputDecoration(labelText: labelText),
        validationMessages: {'required': (_) => requiredErrorText, 'noDigits': (_) => containsDigitsErrorText},
      ),
    );
  }
}
