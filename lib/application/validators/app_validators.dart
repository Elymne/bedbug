import 'package:reactive_forms/reactive_forms.dart';

/// Validators personnalisés compatibles avec [ReactiveForm].
///
/// Chaque validator est une instance `const` d'une classe étendant
/// [Validator<dynamic>], à passer dans la liste `validators` d'un
/// [FormControl]. Appliqués au niveau du [FormControl], pas du widget.
class AppValidators {
  AppValidators._();

  /// Vérifie que le champ n'est pas vide ou nul.
  static const required = _RequiredValidator();

  /// Vérifie que la valeur correspond au format d'une adresse email.
  ///
  /// Retourne `null` si vide — déléguer la vérification à [required].
  static const email = _EmailValidator();

  /// Vérifie que le mot de passe contient au moins 6 caractères.
  ///
  /// Retourne `null` si vide — déléguer la vérification à [required].
  static const password = _PasswordValidator();

  /// Vérifie que la valeur ne contient aucun chiffre.
  ///
  /// Retourne `null` si vide — déléguer la vérification à [required].
  static const noDigits = _NoDigitsValidator();

  /// Vérifie que la valeur est un nombre décimal valide.
  ///
  /// Accepte `.` ou `,` comme séparateur. Retourne `null` si vide.
  static const decimal = _DecimalValidator();

  /// Vérifie que la valeur décimale est positive ou nulle.
  ///
  /// Retourne `null` si non parseable — déléguer à [decimal].
  static const notNegative = _NotNegativeValidator();
}

class _RequiredValidator extends Validator<dynamic> {
  const _RequiredValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value == null) return {'required': true};
    if (value is String && value.trim().isEmpty) return {'required': true};
    return null;
  }
}

class _EmailValidator extends Validator<dynamic> {
  const _EmailValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return {'email': true};
    }
    return null;
  }
}

class _PasswordValidator extends Validator<dynamic> {
  const _PasswordValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    if (value.length < 6) return {'minLength': true};
    return null;
  }
}

class _NoDigitsValidator extends Validator<dynamic> {
  const _NoDigitsValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    if (RegExp(r'\d').hasMatch(value)) return {'noDigits': true};
    return null;
  }
}

class _DecimalValidator extends Validator<dynamic> {
  const _DecimalValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    if (!RegExp(r'^\d+([.,]\d+)?$').hasMatch(value.trim())) {
      return {'decimal': true};
    }
    return null;
  }
}

class _NotNegativeValidator extends Validator<dynamic> {
  const _NotNegativeValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed != null && parsed < 0) return {'notNegative': true};
    return null;
  }
}
