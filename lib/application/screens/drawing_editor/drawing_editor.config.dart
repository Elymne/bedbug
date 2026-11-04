import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';

/// Style commun des boutons qui flottent par-dessus le dessin : un rond clair, bordé, qui se détache de la surface.
final ButtonStyle drawingEditorButtonStyle = IconButton.styleFrom(
  backgroundColor: AppColors.surface,
  foregroundColor: AppColors.onLight,
  side: const BorderSide(color: AppColors.border),
);
