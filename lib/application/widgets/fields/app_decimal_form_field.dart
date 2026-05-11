import 'package:bedbug/application/validators/app_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champ de formulaire reactive pour la saisie de nombres décimaux positifs.
///
/// S'intègre avec [ReactiveForm] via [formControlName]. Restreint la saisie
/// en temps réel aux chiffres et à un seul séparateur décimal (`.` ou `,`).
///
/// Le [FormControl] associé doit déclarer [AppValidators.decimal] et
/// [AppValidators.notNegative] pour que les messages d'erreur s'affichent.
class ReactiveAppDecimalFormField extends StatelessWidget {
  /// Crée un [ReactiveAppDecimalFormField] avec les paramètres fournis.
  const ReactiveAppDecimalFormField({
    required this.formControlName,
    required this.labelText,
    required this.invalidErrorText,
    required this.negativeErrorText,
    super.key,
  });

  /// Nom du contrôle dans le [FormGroup] parent.
  final String formControlName;

  /// Libellé affiché dans le champ.
  final String labelText;

  /// Message d'erreur affiché lorsque la valeur n'est pas un nombre valide.
  final String invalidErrorText;

  /// Message d'erreur affiché lorsque la valeur est négative.
  final String negativeErrorText;

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField<String>(
      formControlName: formControlName,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [_DecimalInputFormatter()],
      decoration: InputDecoration(labelText: labelText),
      validationMessages: {
        'decimal': (_) => invalidErrorText,
        'notNegative': (_) => negativeErrorText,
      },
    );
  }
}

/// Formateur qui autorise uniquement les chiffres et un seul séparateur
/// décimal (`.` ou `,`).
class _DecimalInputFormatter extends TextInputFormatter {
  const _DecimalInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!RegExp(r'^[\d]*([.,][\d]*)?$').hasMatch(newValue.text)) {
      return oldValue;
    }
    return newValue;
  }
}
