import 'package:bedbug/features/content/domain/object_values/flair_suggestion.dart';
import 'package:bedbug/features/content/domain/usecases/get_flair_suggestions_usecase.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/usecases/get_user_suggestions_usecase.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SearchSuggestionsNotifier].
///
/// `autoDispose` : les suggestions repartent de zéro à chaque ouverture de
/// l'écran de recherche.
final searchSuggestionsNotifierProvider =
    AsyncNotifierProvider.autoDispose<SearchSuggestionsNotifier, SearchSuggestionsState>(SearchSuggestionsNotifier.new);

/// Notifier des suggestions d'autocomplétion sous le champ de recherche : flairs puis utilisateurs.
class SearchSuggestionsNotifier extends AsyncNotifier<SearchSuggestionsState> {
  /// Cas d'usage de recherche des flairs correspondant à la saisie.
  late final _getFlairSuggestionsUsecase = ref.read(getFlairSuggestionsUsecaseProvider);

  /// Cas d'usage de recherche des utilisateurs correspondant à la saisie.
  late final _getUserSuggestionsUsecase = ref.read(getUserSuggestionsUsecaseProvider);

  /// Dernière saisie reçue, pour ignorer la réponse d'une saisie déjà dépassée.
  String _latestInput = '';

  @override
  Future<SearchSuggestionsState> build() async {
    return SearchSuggestionsState(flairs: const [], users: const []);
  }

  /// Met à jour les suggestions pour la saisie [input].
  ///
  /// Flairs et utilisateurs sont cherchés en parallèle. L'état ne passe pas
  /// par `AsyncLoading` : les suggestions précédentes restent affichées le
  /// temps du calcul, pour éviter un clignotement à chaque frappe. Une
  /// recherche ratée n'empêche pas de chercher : sa liste reste simplement
  /// vide, sans message d'erreur.
  ///
  /// - [input] : texte actuellement saisi dans le champ de recherche.
  Future<void> search(String input) async {
    _latestInput = input;
    final flairResultFuture = _getFlairSuggestionsUsecase(GetFlairSuggestionsParams(input: input));
    final userResultFuture = _getUserSuggestionsUsecase(GetUserSuggestionsParams(input: input));
    final flairResult = await flairResultFuture;
    final userResult = await userResultFuture;
    if (input != _latestInput) {
      return;
    }

    state = AsyncData(
      SearchSuggestionsState(flairs: flairResult.right ?? const [], users: userResult.right ?? const []),
    );
  }
}

/// État des suggestions de recherche.
class SearchSuggestionsState extends NotifierState {
  /// Crée un [SearchSuggestionsState].
  ///
  /// - [flairs] : flairs proposés pour la saisie courante, affichés en premier.
  /// - [users] : utilisateurs proposés pour la saisie courante, affichés après les flairs.
  SearchSuggestionsState({required this.flairs, required this.users, super.failureMessage});

  /// Flairs proposés pour la saisie courante, affichés en premier.
  final List<FlairSuggestion> flairs;

  /// Utilisateurs proposés pour la saisie courante, affichés après les flairs.
  final List<User> users;
}
