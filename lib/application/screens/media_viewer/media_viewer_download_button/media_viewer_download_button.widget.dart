import 'package:bedbug/application/screens/media_viewer/media_viewer_download_button/media_viewer_download_button.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton de la visionneuse qui enregistre le média affiché dans la galerie du téléphone.
///
/// Remplacé par un indicateur de chargement pendant le téléchargement et l'enregistrement, pour éviter un double tap.
/// Seule partie de la visionneuse à observer l'enregistrement : les médias ne se reconstruisent pas pendant ce temps.
class MediaViewerDownloadButton extends ConsumerWidget {
  /// Crée un [MediaViewerDownloadButton].
  ///
  /// - [currentMediaUrl] : retourne l'adresse du média affiché au moment du tap.
  const MediaViewerDownloadButton({super.key, required this.currentMediaUrl});

  /// Retourne l'adresse du média affiché au moment du tap.
  ///
  /// Une fonction plutôt qu'une adresse : l'utilisateur fait défiler les médias sans que ce bouton se reconstruise.
  final String Function() currentMediaUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaViewerDownloadButtonNotifierWatcher = ref.watch(mediaViewerDownloadButtonNotifierProvider);
    if (mediaViewerDownloadButtonNotifierWatcher.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onDark),
        ),
      );
    }
    return IconButton(
      onPressed: () => _download(context, ref),
      tooltip: context.loc.mediaViewerDownload,
      icon: const AppIcon(AppIcons.download, color: AppColors.onDark),
    );
  }

  /// Enregistre le média affiché dans la galerie du téléphone, puis confirme ou affiche l'erreur.
  ///
  /// - [context] : contexte depuis lequel afficher le résultat.
  /// - [ref] : accès à l'enregistrement.
  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final failureMessage = await ref.read(mediaViewerDownloadButtonNotifierProvider.notifier).save(currentMediaUrl());
    if (!context.mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      return;
    }
    AppSnackbar.showSuccess(context, context.loc.mediaViewerSaveSuccess);
  }
}
