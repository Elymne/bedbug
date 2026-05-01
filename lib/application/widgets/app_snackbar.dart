import 'package:bedbug/app_root.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';

/// Utilitaire d'affichage des snackbars de l'application.
///
/// Propose des méthodes statiques pour afficher des messages d'erreur ou de succès.
/// Les snackbars ne se ferment pas automatiquement — un bouton de fermeture manuel est fourni.
class AppSnackbar {
  AppSnackbar._();

  /// Affiche une snackbar d'erreur avec le [message] fourni.
  static void showError(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: AppColors.failure);
  }

  /// Affiche une snackbar de succès avec le [message] fourni.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: AppColors.success);
  }

  /// Affiche une snackbar avec le [message] et la [backgroundColor] fournis.
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
  }) {
    if (messengerKey.currentState == null) return;
    messengerKey.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: "context.loc.close",
            textColor: Colors.white,
            onPressed: () {
              messengerKey.currentState?.hideCurrentSnackBar();
            },
          ),
        ),
      );
  }
}
