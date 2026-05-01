import 'package:flutter/material.dart';

/// Palette de couleurs de référence de l'application.
class AppColors {
  AppColors._();

  /// Couleur primaire.
  static const Color primary = Color(0xFFFF7DA4);

  /// Couleur de fond de l'application.
  static const Color background = Color(0xFFFFF8F1);

  /// Couleur de fond des cards, des inputs, checkbox et j'en passe.
  static const Color surface = Color(0xFFFFFFFF);

  /// Couleur des éléments sur une surface claire.
  static const Color onLight = Color(0xFF515151);

  /// Couleur des éléments sur une surface sombre.
  static const Color onDark = Color(0xFFFFFFFF);

  /// Couleur des composants désactivés.
  static const Color disabled = Color(0xFFA0A0A0);

  /// Couleurs informatives.
  static const Color info = Color(0xFF51C2FF);
  static const Color success = Color(0xFF85FF4D);
  static const Color failure = Color(0xFFFF4141);
}
