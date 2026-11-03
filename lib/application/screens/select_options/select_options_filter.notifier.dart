import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Délai sans frappe avant d'appliquer le filtre.
const Duration _kFilterDebounce = Duration(milliseconds: 300);

/// Provider du [SelectOptionsFilterNotifier].
///
/// `autoDispose` : le filtre repart de zéro à chaque ouverture de la page.
final selectOptionsFilterNotifierProvider = NotifierProvider.autoDispose<SelectOptionsFilterNotifier, String>(
  SelectOptionsFilterNotifier.new,
);

/// Notifier portant le filtre appliqué à la liste des options, en minuscules et sans espaces de bordure.
///
/// Le filtre ne suit la saisie qu'après une pause : la liste ne se recompose
/// pas à chaque frappe.
class SelectOptionsFilterNotifier extends Notifier<String> {
  /// Minuteur du filtrage en attente, annulé à chaque nouvelle frappe.
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return '';
  }

  /// Applique [input] comme filtre si aucune autre frappe ne suit pendant le délai.
  ///
  /// - [input] : texte actuellement saisi dans le champ de filtrage.
  void updateInput(String input) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_kFilterDebounce, () {
      state = input.trim().toLowerCase();
    });
  }
}
