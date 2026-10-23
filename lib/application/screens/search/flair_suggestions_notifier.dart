import 'package:bedbug/features/content/domain/object_values/flair_suggestion.dart';
import 'package:bedbug/features/content/domain/usecases/get_flair_suggestions_usecase.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [FlairSuggestionsNotifier].
///
/// `autoDispose` : les suggestions repartent de zéro à chaque ouverture de
/// l'écran de recherche.
final flairSuggestionsNotifierProvider =
    AsyncNotifierProvider.autoDispose<FlairSuggestionsNotifier, FlairSuggestionsState>(FlairSuggestionsNotifier.new);

/// Notifier des flairs proposés en autocomplétion sous le champ de recherche.
class FlairSuggestionsNotifier extends AsyncNotifier<FlairSuggestionsState> {
  /// Cas d'usage de recherche des flairs correspondant à la saisie.
  late final _getFlairSuggestionsUsecase = ref.read(getFlairSuggestionsUsecaseProvider);

  /// Dernière saisie reçue, pour ignorer la réponse d'une saisie déjà dépassée.
  String _latestInput = '';

  @override
  Future<FlairSuggestionsState> build() async {
    return FlairSuggestionsState(suggestions: const []);
  }

  /// Met à jour les suggestions pour la saisie [input].
  ///
  /// L'état ne passe pas par `AsyncLoading` : les suggestions précédentes
  /// restent affichées le temps du calcul, pour éviter un clignotement à
  /// chaque frappe.
  ///
  /// - [input] : texte actuellement saisi dans le champ de recherche.
  Future<void> search(String input) async {
    _latestInput = input;
    final result = await _getFlairSuggestionsUsecase(GetFlairSuggestionsParams(input: input));
    if (input != _latestInput) {
      return;
    }

    result.fold(
      // Une suggestion ratée n'empêche pas de chercher : on n'en propose
      // simplement aucune, sans message d'erreur.
      onFailure: (GetFlairSuggestionsFailure failure) {
        state = AsyncData(FlairSuggestionsState(suggestions: const []));
      },
      onSuccess: (List<FlairSuggestion> suggestions) {
        state = AsyncData(FlairSuggestionsState(suggestions: suggestions));
      },
    );
  }
}

/// État des suggestions de flairs.
class FlairSuggestionsState extends NotifierState {
  /// Crée un [FlairSuggestionsState].
  ///
  /// - [suggestions] : flairs proposés pour la saisie courante.
  FlairSuggestionsState({required this.suggestions, super.failureMessage});

  /// Flairs proposés pour la saisie courante.
  final List<FlairSuggestion> suggestions;
}
