import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:bedbug/features/content/domain/object_values/flair_suggestion.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
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
