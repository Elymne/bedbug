import 'package:bedbug/application/app_root.dart';
import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:flutter/material.dart';

/// Utilitaire d'affichage des snackbars de l'application.
///
/// Propose des méthodes statiques pour afficher des messages d'erreur ou de succès.
/// Les snackbars flottent au-dessus du contenu, se ferment seules après quelques
/// secondes et portent une croix pour les fermer plus tôt.
class AppSnackbar {
  AppSnackbar._();

  /// Affiche une snackbar d'erreur avec le [message] fourni.
  static void showError(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: AppColors.failure, foregroundColor: AppColors.onDark);
  }

  /// Affiche une snackbar de succès avec le [message] fourni.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: AppColors.success, foregroundColor: AppColors.onLight);
  }

  /// Affiche une snackbar avec le [message] et les couleurs fournis.
  ///
  /// Le contenu est construit à la main plutôt qu'avec `action` ou
  /// `showCloseIcon` de [SnackBar] : ces deux options imposent un bouton de
  /// 48 px de haut qui double la hauteur de la snackbar pour un message d'une
  /// seule ligne.
  ///
  /// - [context] : contexte utilisé pour lire les traductions.
  /// - [message] : texte affiché dans la snackbar.
  /// - [backgroundColor] : couleur de fond de la snackbar.
  /// - [foregroundColor] : couleur du texte et de la croix de fermeture.
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppValues.baseMargin),
          padding: const EdgeInsets.only(left: 16, right: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          content: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: foregroundColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: messenger.hideCurrentSnackBar,
                tooltip: AppLocalizations.of(context)!.close,
                icon: const Icon(Icons.close_rounded),
                iconSize: 18,
                color: foregroundColor,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
        ),
      );
  }
}
