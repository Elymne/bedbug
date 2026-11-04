import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Popup expliquant à quoi sert la signature et comment elle circule, avant que l'utilisateur ne crée la sienne.
///
/// Sans serveur, une signature n'est qu'un style : rien n'empêche quelqu'un d'autre de signer sous le même pseudo. Le
/// formulaire ressemble pourtant à une inscription ; la popup lève l'ambiguïté avant la saisie, pour que personne ne
/// prenne sa signature pour un compte protégé. À afficher via [show].
class SignatureInfoDialog extends ConsumerWidget {
  /// Crée un [SignatureInfoDialog].
  const SignatureInfoDialog({super.key});

  /// Affiche la popup.
  ///
  /// - [context] : contexte depuis lequel ouvrir la popup.
  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.barrier,
      builder: (dialogContext) => const SignatureInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: Text(l10n.signatureSetupInfoTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(l10n.signatureSetupInfoStyle),
          Text(l10n.signatureSetupInfoNotAccount, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(l10n.signatureSetupInfoTravel),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.signatureSetupInfoConfirm))],
    );
  }
}
