import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.config.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.extension.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_flair/get_contents_by_flair.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_flair/get_contents_by_flair.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentsByFlairUsecase].
final getContentsByFlairUsecaseProvider = Provider<GetContentsByFlairUsecase>((ref) {
  return GetContentsByFlairUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère une page des contenus rattachés à un flair précis.
///
/// Sert la page de résultats ouverte quand l'utilisateur choisit un flair parmi les suggestions d'autocomplétion :
/// son intention est alors explicite (« montre-moi /france »), on retourne donc uniquement les contenus de ce flair
/// exact, sans la correspondance approximative de la recherche globale.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter les contenus dans le même ordre de
/// pertinence que la home page, et lus page par page.
class GetContentsByFlairUsecase
    extends Usecase<GetContentsByFlairParams, GetContentsByFlairFailure, CursorPage<ContentDetailed>> {
  /// Crée un [GetContentsByFlairUsecase].
  GetContentsByFlairUsecase(this._contentRepository, this._errorLogRepository);

  /// Repository des contenus.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<GetContentsByFlairFailure, CursorPage<ContentDetailed>>> call(GetContentsByFlairParams params) async {
    try {
      final flair = params.flair.toFlair();
      if (flair == null) {
        return const Right(CursorPage(items: [], nextCursor: null));
      }

      return Right(await _contentRepository.getPageByFlair(flair, after: params.after, limit: contentPageSize));
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentsByFlairUsecase', error, stackTrace);
      return const Left(GetContentsByFlairFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentsByFlairUsecase', error, stackTrace);
      return const Left(GetContentsByFlairFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentsByFlairUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetContentsByFlairUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetContentsByFlairFailure.unknown);
    }
  }
}
