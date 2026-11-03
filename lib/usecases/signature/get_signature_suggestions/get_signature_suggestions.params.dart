import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/signature/get_signature_suggestions/get_signature_suggestions.usecase.dart';

/// Paramètres du [GetSignatureSuggestionsUsecase].
class GetSignatureSuggestionsParams extends Params {
  /// Crée des [GetSignatureSuggestionsParams].
  ///
  /// - [input] : saisie brute de l'utilisateur, avec ou sans `s/` initial.
  const GetSignatureSuggestionsParams({required this.input});

  /// Saisie brute de l'utilisateur, avec ou sans `s/` initial.
  final String input;
}
