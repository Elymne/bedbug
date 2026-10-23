import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre de clics exigés pour confirmer l'ajout d'un lien LinkedIn.
const int linkedinRequiredClicks = 100;

/// Provider du [LinkedinClickCounterNotifier].
///
/// `autoDispose` : le compteur repart de zéro à chaque ouverture de la popup.
final linkedinClickCounterNotifierProvider = NotifierProvider.autoDispose<LinkedinClickCounterNotifier, int>(
  LinkedinClickCounterNotifier.new,
);

/// Compte les clics de l'utilisateur dans la popup de confirmation LinkedIn.
///
/// Ajouter LinkedIn sur une app sans serveur ni recruteur mérite une
/// confirmation à la hauteur : [linkedinRequiredClicks] clics, pas un de moins.
class LinkedinClickCounterNotifier extends Notifier<int> {
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
