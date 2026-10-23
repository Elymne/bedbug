import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_text.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bedbug du splashscreen, version clown : nez rouge compris.
const _kClownBedbug = '( ノ ^🔴^)ノ';

/// Popup finale du parcours LinkedIn : un bedbug clown et un gros « BOUFON ! ».
///
/// Récompense l'utilisateur qui a cliqué 100 fois pour afficher son LinkedIn,
/// sans que rien ne soit ajouté : il s'est fait avoir, d'où le bouffon.
class ClownBedbugDialog extends ConsumerWidget {
  /// Crée un [ClownBedbugDialog].
  const ClownBedbugDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 24,
        children: [
          const SizedBox(height: 8),
          const AppGhostText(
            label: _kClownBedbug,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            isAnimating: true,
            ghostColor: AppColors.failure,
            speed: 3,
            intensity: 1.5,
          ),
          AppGhostText(
            label: l10n.settingsLinkedinClownTitle,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            isAnimating: true,
            speed: 2,
            intensity: 2,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.settingsLinkedinClownButton)),
      ],
    );
  }
}
