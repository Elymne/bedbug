import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content/content.extension.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.config.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.failure.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.params.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetFlairSuggestionsUsecase].
final getFlairSuggestionsUsecaseProvider = Provider<GetFlairSuggestionsUsecase>((ref) {
  return GetFlairSuggestionsUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
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
  GetFlairSuggestionsUsecase(this._contentRepository, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetFlairSuggestionsFailure, List<FlairSuggestion>>> call(GetFlairSuggestionsParams params) async {
    try {
      final prefix = params.input.toFlair();
      if (prefix == null) {
        return const Right([]);
      }

      final flairs = await _contentRepository.getFlairsStartingWith(prefix);
      return Right(_rank(flairs));
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetFlairSuggestionsUsecase', error, stackTrace);
      return const Left(GetFlairSuggestionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetFlairSuggestionsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetFlairSuggestionsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetFlairSuggestionsFailure.unknown);
    }
  }

  /// Regroupe [flairs] en suggestions, les plus fournies en premier, limitées à [maxFlairSuggestions].
  ///
  /// À nombre de contenus égal, l'ordre alphabétique départage, pour que la liste reste stable d'une frappe à
  /// l'autre.
  ///
  /// - [flairs] : flair de chaque contenu correspondant, un par contenu.
  List<FlairSuggestion> _rank(List<String> flairs) {
    final countsByFlair = <String, int>{};
    for (final flair in flairs) {
      countsByFlair.update(flair, (count) => count + 1, ifAbsent: () => 1);
    }
    final suggestions = [
      for (final entry in countsByFlair.entries) FlairSuggestion(flair: entry.key, contentCount: entry.value),
    ];
    suggestions.sort((first, second) {
      final countComparison = second.contentCount.compareTo(first.contentCount);
      if (countComparison != 0) {
        return countComparison;
      }
      return first.flair.compareTo(second.flair);
    });
    return suggestions.take(maxFlairSuggestions).toList();
  }
}
