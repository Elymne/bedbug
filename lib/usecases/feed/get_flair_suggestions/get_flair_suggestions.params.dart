import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.usecase.dart';

/// Paramètres du [GetFlairSuggestionsUsecase].
class GetFlairSuggestionsParams extends Params {
  /// Crée des [GetFlairSuggestionsParams].
  ///
  /// - [input] : saisie brute de l'utilisateur, avec ou sans `/` initial.
  const GetFlairSuggestionsParams({required this.input});

  /// Saisie brute de l'utilisateur, avec ou sans `/` initial.
  final String input;
}
