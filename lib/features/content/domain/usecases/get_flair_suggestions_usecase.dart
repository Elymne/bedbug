import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content.repository.dart';
import 'package:bedbug/resources/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/flair.extension.dart';
import 'package:bedbug/resources/content/flair_suggestion.value_object.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal de flairs proposés en autocomplétion.
const int maxFlairSuggestions = 6;

/// Provider du [GetFlairSuggestionsUsecase].
final getFlairSuggestionsUsecaseProvider = Provider<GetFlairSuggestionsUsecase>((ref) {
  return GetFlairSuggestionsUsecase(ref.read(contentRepositoryProvider));
});

/// Propose les flairs existants correspondant au début de la saisie de l'utilisateur.
///
/// Le flair étant un texte libre, l'utilisateur ne peut pas deviner quels
/// flairs existent réellement sur son appareil. Comme sur Reddit, on lui
/// suggère pendant la frappe les flairs qui commencent par ce qu'il tape,
/// les plus fournis en premier : un tap l'amène directement aux contenus du
/// flair, sans passer par la recherche globale approximative.
///
/// La saisie est normalisée comme un flair (`/France` → `france`), pour que
/// l'utilisateur puisse taper le `/` ou non.
class GetFlairSuggestionsUsecase
    extends Usecase<GetFlairSuggestionsParams, GetFlairSuggestionsFailure, List<FlairSuggestion>> {
  /// Crée un [GetFlairSuggestionsUsecase].
  GetFlairSuggestionsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<GetFlairSuggestionsFailure, List<FlairSuggestion>>> call(GetFlairSuggestionsParams params) async {
    try {
      final prefix = params.input.toFlair();
      if (prefix == null) {
        return const Right([]);
      }

      final suggestions = await _contentRepository.getFlairsStartingWith(prefix, limit: maxFlairSuggestions);
      return Right(suggestions);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetFlairSuggestionsUsecase', error, stackTrace);
      return const Left(GetFlairSuggestionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetFlairSuggestionsUsecase', error, stackTrace);
      return const Left(GetFlairSuggestionsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetFlairSuggestionsUsecase].
enum GetFlairSuggestionsFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la recherche de suggestions.
  unknown,
}

/// Paramètres du [GetFlairSuggestionsUsecase].
class GetFlairSuggestionsParams extends Params {
  /// Crée des [GetFlairSuggestionsParams].
  ///
  /// - [input] : saisie brute de l'utilisateur, avec ou sans `/` initial.
  const GetFlairSuggestionsParams({required this.input});

  /// Saisie brute de l'utilisateur, avec ou sans `/` initial.
  final String input;
}
