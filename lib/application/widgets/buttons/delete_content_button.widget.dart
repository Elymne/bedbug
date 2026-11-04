import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/buttons/delete_content_button.notifier.dart';
import 'package:bedbug/application/widgets/dialogs/delete_content_dialog.widget.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Corbeille d'un contenu publié par l'utilisateur, qui le supprime après confirmation.
///
/// Partagée par la liste « Mes posts » et la page de détail d'un contenu. Observe la suppression en cours pour se
/// désactiver le temps qu'elle aboutisse : deux taps rapprochés ne lancent pas deux suppressions. Les listes qui
/// affichent le contenu se rechargent d'elles-mêmes en cas de succès.
class DeleteContentButton extends ConsumerWidget {
  /// Crée un [DeleteContentButton].
  ///
  /// - [contentId] : identifiant du contenu à supprimer.
  /// - [onDeleted] : appelé une fois le contenu supprimé (fermer la page qui l'affichait, par exemple).
  const DeleteContentButton({super.key, required this.contentId, this.onDeleted});

  /// Identifiant du contenu à supprimer.
  final String contentId;

  /// Appelé une fois le contenu supprimé.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteContentButtonNotifierWatcher = ref.watch(deleteContentButtonNotifierProvider);

    return IconButton(
      onPressed: deleteContentButtonNotifierWatcher.isLoading ? null : () => _onDelete(context, ref),
      tooltip: context.loc.deleteContentButton,
      icon: const AppIcon(AppIcons.delete, color: AppColors.failure),
    );
  }

  /// Demande confirmation, supprime le contenu, puis affiche le résultat.
  ///
  /// En cas d'échec, l'erreur est affichée et rien d'autre ne se passe.
  ///
  /// - [context] : contexte depuis lequel ouvrir la confirmation et afficher le résultat.
  /// - [ref] : accès à la suppression.
  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    // Lu avant la confirmation : `ref` n'est plus utilisable si le bouton disparaît entre-temps.
    final deleteContentButtonNotifier = ref.read(deleteContentButtonNotifierProvider.notifier);
    final isConfirmed = await DeleteContentDialog.show(context);
    if (!isConfirmed || !context.mounted) {
      return;
    }

    final failureMessage = await deleteContentButtonNotifier.delete(contentId);
    if (!context.mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      return;
    }
    AppSnackbar.showSuccess(context, context.loc.deleteContentSuccess);
    onDeleted?.call();
  }
}
