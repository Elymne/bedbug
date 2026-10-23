import 'package:bedbug/features/content/domain/object_values/flair_suggestion.dart';
import 'package:bedbug/features/content/domain/usecases/get_flair_suggestions_usecase.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/usecases/get_signature_suggestions_usecase.dart';
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
  late final _getSignatureSuggestionsUsecase = ref.read(getSignatureSuggestionsUsecaseProvider);

  /// Dernière saisie reçue, pour ignorer la réponse d'une saisie déjà dépassée.
  String _latestInput = '';

  @override
  Future<SearchSuggestionsState> build() async {
    return SearchSuggestionsState(flairs: const [], signatures: const []);
  }

  /// Met à jour les suggestions pour la saisie [input].
  ///
  /// Flairs et signatures sont cherchés en parallèle. L'état ne passe pas
  /// par `AsyncLoading` : les suggestions précédentes restent affichées le
  /// temps du calcul, pour éviter un clignotement à chaque frappe. Une
  /// recherche ratée n'empêche pas de chercher : sa liste reste simplement
  /// vide, sans message d'erreur.
  ///
  /// - [input] : texte actuellement saisi dans le champ de recherche.
  Future<void> search(String input) async {
    _latestInput = input;
    final flairResultFuture = _getFlairSuggestionsUsecase(GetFlairSuggestionsParams(input: input));
    final signatureResultFuture = _getSignatureSuggestionsUsecase(GetSignatureSuggestionsParams(input: input));
    final flairResult = await flairResultFuture;
    final signatureResult = await signatureResultFuture;
    if (input != _latestInput) {
      return;
    }

    state = AsyncData(
      SearchSuggestionsState(flairs: flairResult.right ?? const [], signatures: signatureResult.right ?? const []),
    );
  }
}

/// État des suggestions de recherche.
class SearchSuggestionsState extends NotifierState {
  /// Crée un [SearchSuggestionsState].
  ///
  /// - [flairs] : flairs proposés pour la saisie courante, affichés en premier.
  /// - [signatures] : signatures proposées pour la saisie courante, affichées après les flairs.
  SearchSuggestionsState({required this.flairs, required this.signatures, super.failureMessage});

  /// Flairs proposés pour la saisie courante, affichés en premier.
  final List<FlairSuggestion> flairs;

  /// Signatures proposées pour la saisie courante, affichées après les flairs.
  final List<Signature> signatures;
}
