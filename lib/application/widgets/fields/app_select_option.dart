import 'package:flutter/painting.dart';

/// Option proposée par une `AppSelectBox`.
class AppSelectOption<T> {
  /// Crée une [AppSelectOption].
  ///
  /// - [value] : valeur portée par l'option.
  /// - [label] : texte affiché, sur lequel porte aussi le filtrage.
  /// - [style] : style du texte, `null` pour le style par défaut.
  const AppSelectOption({required this.value, required this.label, this.style});

  /// Valeur portée par l'option.
  final T value;

  /// Texte affiché, sur lequel porte aussi le filtrage.
  final String label;

  /// Style du texte, `null` pour le style par défaut.
  final TextStyle? style;
}
