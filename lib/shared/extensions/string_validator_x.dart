import 'package:bedbug/application/validators/app_validators.dart' show AppValidators;

/// Extension de validation sur [String] nullable.
///
/// Centralise les règles de validation des chaînes pour un usage métier
/// hors-formulaire. Pour les formulaires, utiliser [AppValidators].
extension StringValidatorX on String? {
  /// Retourne `true` si la valeur est non nulle et non vide après trim.
  bool get isRequiredValid => this != null && this!.trim().isNotEmpty;

  /// Retourne `true` si la valeur correspond au format d'une adresse email valide.
  bool get isEmailValid =>
      isRequiredValid &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(this!.trim());

  /// Retourne `true` si la valeur contient au moins 6 caractères.
  bool get isPasswordValid => this != null && this!.length >= 6;

  /// Retourne `true` si la valeur ne contient aucun chiffre.
  bool get hasNoDigits => this != null && !RegExp(r'\d').hasMatch(this!);

  /// Retourne `true` si la valeur est un nombre décimal positif valide.
  ///
  /// Accepte `.` ou `,` comme séparateur décimal, mais pas les deux.
  /// Ex : `2`, `2.5`, `2,5`. Rejette `2..5`, `2,,5`, `abc`.
  bool get isDecimalNumberValid =>
      this != null && RegExp(r'^\d+([.,]\d+)?$').hasMatch(this!.trim());
}
