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

  /// Métadonnées d'un contenu (sub, temps écoulé).
  static final TextStyle contentMeta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.disabled,
  );

  /// Titre d'un contenu.
  static final TextStyle contentTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onLight,
  );

  /// Texte de prévisualisation d'un contenu.
  static final TextStyle contentPreview = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.onLight,
  );
}
