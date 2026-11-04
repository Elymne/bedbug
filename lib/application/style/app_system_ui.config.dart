import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/services.dart';

/// Style de la barre d'état du système dans toute l'app : opaque, de la couleur du fond, icônes foncées.
///
/// Appliqué au démarrage. Une page qui le change (la page d'échange, dont le ciel passe sous la barre d'état) le
/// rétablit en se fermant.
const SystemUiOverlayStyle appSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: AppColors.background,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);
