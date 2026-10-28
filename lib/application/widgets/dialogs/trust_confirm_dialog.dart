import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Popup de confirmation avant d'afficher un média, ou d'ouvrir un lien, d'un domaine qui n'est pas de confiance.
///
/// Rappelle le domaine concerné : c'est lui que le téléphone va contacter,
/// et c'est sur lui que l'utilisateur doit se décider. Se ferme avec `true`
/// si l'utilisateur confirme, `false` sinon. À afficher via [show].
class TrustConfirmDialog extends ConsumerWidget {
  /// Crée un [TrustConfirmDialog].
  ///
  /// - [title] : question posée (« Afficher ce média ? »).
  /// - [body] : explication, qui cite le domaine.
  /// - [confirmLabel] : libellé du bouton de confirmation.
  const TrustConfirmDialog({super.key, required this.title, required this.body, required this.confirmLabel});

  /// Question posée.
  final String title;

  /// Explication, qui cite le domaine.
  final String body;

  /// Libellé du bouton de confirmation.
  final String confirmLabel;

  /// Affiche la popup et retourne `true` si l'utilisateur confirme.
  ///
  /// - [context] : contexte depuis lequel ouvrir la popup.
  /// - [title] : question posée.
  /// - [body] : explication, qui cite le domaine.
  /// - [confirmLabel] : libellé du bouton de confirmation.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrier,
      builder: (dialogContext) => TrustConfirmDialog(title: title, body: body, confirmLabel: confirmLabel),
    );
    return isConfirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.loc.cancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmLabel)),
      ],
    );
  }
}
