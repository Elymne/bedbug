import 'package:bedbug/application/widgets/signature/linkedin_click_challenge_dialog.config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [LinkedinClickChallengeDialogNotifier].
///
/// `autoDispose` : le compteur repart de zéro à chaque ouverture de la popup.
final linkedinClickChallengeDialogNotifierProvider =
    NotifierProvider.autoDispose<LinkedinClickChallengeDialogNotifier, int>(LinkedinClickChallengeDialogNotifier.new);

/// Compte les clics de l'utilisateur dans la popup de confirmation LinkedIn.
///
/// Ajouter LinkedIn sur une app sans serveur ni recruteur mérite une
/// confirmation à la hauteur : [linkedinRequiredClicks] clics, pas un de moins.
class LinkedinClickChallengeDialogNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  /// Ajoute un clic, sans dépasser [linkedinRequiredClicks].
  void increment() {
    if (state >= linkedinRequiredClicks) {
      return;
    }
    state = state + 1;
  }
}
