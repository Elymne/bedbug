import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Popup de confirmation avant la suppression d'un de ses contenus.
///
/// Rappelle que la suppression est locale : les copies déjà transmises à
/// d'autres appareils ne disparaîtront pas. Se ferme avec `true` si
/// l'utilisateur confirme, `false` sinon. À afficher via [show].
class DeleteContentDialog extends ConsumerWidget {
  /// Crée un [DeleteContentDialog].
  const DeleteContentDialog({super.key});

  /// Affiche la popup et retourne `true` si l'utilisateur confirme la suppression.
  ///
  /// - [context] : contexte depuis lequel ouvrir la popup.
  static Future<bool> show(BuildContext context) async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrier,
      builder: (dialogContext) => const DeleteContentDialog(),
    );
    return isConfirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: Text(l10n.deleteContentDialogTitle),
      content: Text(l10n.deleteContentDialogBody),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.deleteContentDialogCancel)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.failure),
          child: Text(l10n.deleteContentDialogConfirm),
        ),
      ],
    );
  }
}
