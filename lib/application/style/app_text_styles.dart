import 'dart:ui';

import 'package:bedbug/application/style/app_colors.dart';

/// Styles de texte de référence de l'application.
class AppTextStyles {
  AppTextStyles._();

  /// Font des labels au dessus des textfields.
  static final TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onLight,
  );

  /// Font des textes dans les textfields.
  static final TextStyle textfield = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w100,
    color: AppColors.onLight,
  );
}
