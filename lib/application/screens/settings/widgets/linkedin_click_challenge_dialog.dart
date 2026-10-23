import 'package:bedbug/application/screens/settings/linkedin_click_counter_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Popup exigeant [linkedinRequiredClicks] clics pour confirmer l'ajout d'un lien LinkedIn.
///
/// Se ferme d'elle-même avec `true` au dernier clic, ou avec `false` si
/// l'utilisateur abandonne en route.
class LinkedinClickChallengeDialog extends ConsumerWidget {
  /// Crée un [LinkedinClickChallengeDialog].
  const LinkedinClickChallengeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final clickCount = ref.watch(linkedinClickCounterNotifierProvider);

    ref.listen(linkedinClickCounterNotifierProvider, (previous, next) {
      if (next >= linkedinRequiredClicks) {
        Navigator.of(context).pop(true);
      }
    });

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: Text(l10n.settingsLinkedinChallengeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text(l10n.settingsLinkedinChallengeBody(linkedinRequiredClicks)),
          Text(
            '$clickCount / $linkedinRequiredClicks',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onLight),
          ),
          LinearProgressIndicator(
            value: clickCount / linkedinRequiredClicks,
            color: AppColors.primary,
            backgroundColor: AppColors.border,
          ),
          ElevatedButton(
            onPressed: () => ref.read(linkedinClickCounterNotifierProvider.notifier).increment(),
            child: Text(l10n.settingsLinkedinChallengeButton),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.settingsLinkedinChallengeGiveUp),
        ),
      ],
    );
  }
}
