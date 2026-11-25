import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.config.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetFilteredContentsUsecase].
final getFilteredContentsUsecaseProvider = Provider<GetFilteredContentsUsecase>((ref) {
  return GetFilteredContentsUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère une page des contenus correspondant à une recherche libre de l'utilisateur.
///
/// Sert la recherche « globale » : l'utilisateur a validé sa saisie sans choisir de flair parmi les suggestions, on
/// ne sait donc pas s'il cherche un titre ou un flair. Le texte est comparé aux deux. La description des contenus est
/// volontairement ignorée : la parcourir sur tout le stockage local serait trop coûteux pour le téléphone.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter les contenus dans le même ordre de
/// pertinence que la home page, et lus page par page.
class GetFilteredContentsUsecase
    extends Usecase<GetFilteredContentsParams, GetFilteredContentsFailure, CursorPage<ContentDetailed>> {
  /// Crée un [GetFilteredContentsUsecase].
  GetFilteredContentsUsecase(this._contentRepository, this._errorLogRepository);

  /// Repository des contenus.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<GetFilteredContentsFailure, CursorPage<ContentDetailed>>> call(GetFilteredContentsParams params) async {
    try {
      final query = params.query.trim();
      if (query.isEmpty) {
        return const Right(CursorPage(items: [], nextCursor: null));
      }

      final page = await _contentRepository.getPageMatchingTitleOrFlair(
        query,
        after: params.after,
        limit: contentPageSize,
      );
      return Right(page);
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
