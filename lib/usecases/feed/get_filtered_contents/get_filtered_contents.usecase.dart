import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content.entity.dart';
import 'package:bedbug/resources/content/content.repository.dart';
import 'package:bedbug/resources/content/content.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/feed/get_filtered_contents/get_filtered_contents.failure.dart';
import 'package:bedbug/usecases/feed/get_filtered_contents/get_filtered_contents.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetFilteredContentsUsecase].
final getFilteredContentsUsecaseProvider = Provider<GetFilteredContentsUsecase>((ref) {
  return GetFilteredContentsUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère les contenus correspondant à une recherche libre de l'utilisateur.
///
/// Sert la recherche « globale » : l'utilisateur a validé sa saisie sans
/// choisir de flair parmi les suggestions, on ne sait donc pas s'il cherche
/// un titre ou un flair. Le texte est comparé aux deux. La description des
/// contenus est volontairement ignorée : la parcourir sur tout le stockage
/// local serait trop coûteux pour le téléphone.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter
/// les contenus dans le même ordre de pertinence que la home page.
class GetFilteredContentsUsecase extends Usecase<GetFilteredContentsParams, GetFilteredContentsFailure, List<Content>> {
  /// Crée un [GetFilteredContentsUsecase].
  GetFilteredContentsUsecase(this._contentRepository, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetFilteredContentsFailure, List<Content>>> call(GetFilteredContentsParams params) async {
    try {
      final query = params.query.trim();
      if (query.isEmpty) {
        return const Right([]);
      }

      final contents = await _contentRepository.getAllMatchingTitleOrFlair(query);
      contents.sort((first, second) => second.displayScore.compareTo(first.displayScore));
      return Right(contents);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetFilteredContentsUsecase', error, stackTrace);
      return const Left(GetFilteredContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetFilteredContentsUsecase', error, stackTrace);
      return const Left(GetFilteredContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetFilteredContentsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetFilteredContentsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetFilteredContentsFailure.unknown);
    }
  }
}
