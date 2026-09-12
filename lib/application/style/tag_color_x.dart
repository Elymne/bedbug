import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/features/content/domain/enums/tag_color.dart';
import 'package:flutter/material.dart';

/// Correspondance entre la clé sémantique [TagColor] du domaine et une
/// couleur concrète de [AppColors].
///
/// Le domaine ne connaît pas Flutter : c'est cette extension, côté
/// application, qui fait le pont entre les deux mondes.
extension TagColorX on TagColor {
  /// Couleur [AppColors] correspondant à cette clé sémantique.
  Color get flutterColor {
    return switch (this) {
      TagColor.blue => AppColors.info,
      TagColor.red => AppColors.failure,
      TagColor.purple => AppColors.purple,
      TagColor.orange => AppColors.orange,
    };
  }
}
