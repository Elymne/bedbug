import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';

/// Thème principal de l'application.
class AppTheme {
  /// Thème clair de l'application.
  /// L'application va aussi proposer un thème dark soft (fond grisé) en fonction des paramètres utilisateurs.
  static ThemeData get light => ThemeData(
    fontFamily: 'Quicksand',

    /// * Colors.
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
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
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.failure)),
      focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.failure, width: 2)),
      disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.disabled)),
    ),
  );

  AppTheme._();
}
