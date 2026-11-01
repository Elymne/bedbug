import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:flutter/material.dart';

/// Thème principal de l'application.
class AppTheme {
  /// Thème clair de l'application.
  /// L'application va aussi proposer un thème dark soft (fond grisé) en fonction des paramètres utilisateurs.
  static ThemeData get light {
    return ThemeData(
      fontFamily: 'Quicksand',

      /// * Colors.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      disabledColor: AppColors.disabled,

      /// * Elevated Buttons style.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      /// Outlined Button style.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      /// * Checkboxes style.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      /// * Textfields style.
      // Le label reste flottant pour laisser voir le placeholder d'exemple dans un champ vide.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: const TextStyle(color: AppColors.disabled),
        labelStyle: const TextStyle(color: AppColors.onLight),
        floatingLabelStyle: const TextStyle(color: AppColors.onLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _fieldBorder(AppColors.onLight),
        enabledBorder: _fieldBorder(AppColors.onLight),
        focusedBorder: _fieldBorder(AppColors.onLight),
        errorBorder: _fieldBorder(AppColors.failure),
        focusedErrorBorder: _fieldBorder(AppColors.failure),
        disabledBorder: _fieldBorder(AppColors.disabled),
      ),
    );
  }

  AppTheme._();

  /// Bordure arrondie d'un champ de formulaire.
  ///
  /// - [color] : couleur du trait.
  static OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppValues.fieldRadius),
      borderSide: BorderSide(color: color),
    );
  }
}
