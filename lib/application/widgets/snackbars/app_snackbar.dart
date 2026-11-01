import 'package:bedbug/application/app_root.dart';
import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/application/widgets/snackbars/snackbar_bedbug_background.dart';
import 'package:bedbug/application/widgets/snackbars/snackbar_pulse_border.dart';
import 'package:flutter/material.dart';

/// Rayon des coins de la snackbar, repris par sa bordure pulsante.
const double _kBorderRadius = 12;

/// Intensité par défaut de l'animation de fond d'une snackbar de succès : discrète.
const double _kSuccessIntensity = 0.2;

/// Intensité par défaut de l'animation de fond d'une snackbar d'erreur : maximale, impossible à rater.
const double _kErrorIntensity = 1;

/// Bedbug du fond d'une snackbar de succès.
const String _kSuccessBedbug = '( ノ ^o^)ノ';

/// Bedbug du fond d'une snackbar d'erreur.
const String _kErrorBedbug = '(╯°□°)╯';

/// Utilitaire d'affichage des snackbars de l'application.
///
/// Propose des méthodes statiques pour afficher des messages d'erreur ou de succès.
/// Les snackbars ont un fond sombre et un texte blanc, sur une rangée de
/// bedbugs animés, dans une bordure dont l'épaisseur pulse ; leur couleur
/// porte le ton du message : vert et lent pour un succès, rouge et frénétique
/// pour une erreur. Elles flottent au-dessus du
/// contenu, se ferment seules après quelques secondes et portent une croix
/// pour les fermer plus tôt.
class AppSnackbar {
  AppSnackbar._();

  /// Affiche une snackbar d'erreur avec le [message] fourni.
  ///
  /// - [context] : contexte utilisé pour lire les traductions.
  /// - [message] : texte affiché dans la snackbar.
  /// - [intensity] : intensité de l'animation de fond, de 0 à 1 (défaut : maximale).
  static void showError(BuildContext context, String message, {double intensity = _kErrorIntensity}) {
    _show(context, message: message, bedbug: _kErrorBedbug, ghostColor: AppColors.failure, intensity: intensity);
  }

  /// Affiche une snackbar de succès avec le [message] fourni.
  ///
  /// - [context] : contexte utilisé pour lire les traductions.
  /// - [message] : texte affiché dans la snackbar.
  /// - [intensity] : intensité de l'animation de fond, de 0 à 1 (défaut : faible).
  static void showSuccess(BuildContext context, String message, {double intensity = _kSuccessIntensity}) {
    _show(context, message: message, bedbug: _kSuccessBedbug, ghostColor: AppColors.success, intensity: intensity);
  }

  /// Affiche une snackbar avec le [message], sur un fond de bedbugs animés.
  ///
  /// Le contenu est construit à la main plutôt qu'avec `action` ou
  /// `showCloseIcon` de [SnackBar] : ces deux options imposent un bouton de
  /// 48 px de haut qui double la hauteur de la snackbar pour un message d'une
  /// seule ligne. Le `padding` de la [SnackBar] est nul pour que le fond
  /// animé en couvre toute la surface ; les marges sont portées par le message.
  ///
  /// - [context] : contexte utilisé pour lire les traductions.
  /// - [message] : texte affiché dans la snackbar.
  /// - [bedbug] : kaomoji répété dans le fond.
  /// - [ghostColor] : couleur du ghost des bedbugs du fond.
  /// - [intensity] : intensité de l'animation de fond, de 0 à 1.
  static void _show(
    BuildContext context, {
    required String message,
    required String bedbug,
    required Color ghostColor,
    required double intensity,
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
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kBorderRadius)),
          elevation: 2,
          backgroundColor: AppColors.onLight,
          duration: const Duration(seconds: 3),
          content: Stack(
            children: [
              Positioned.fill(
                child: SnackbarBedbugBackground(bedbug: bedbug, ghostColor: ghostColor, intensity: intensity),
              ),
              Positioned.fill(
                child: SnackbarPulseBorder(color: ghostColor, intensity: intensity, borderRadius: _kBorderRadius),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: messenger.hideCurrentSnackBar,
                      tooltip: AppLocalizations.of(context)!.close,
                      icon: const AppIcon(AppIcons.close),
                      iconSize: 18,
                      color: AppColors.onDark,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
