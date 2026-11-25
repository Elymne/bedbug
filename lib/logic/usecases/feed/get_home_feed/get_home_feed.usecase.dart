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
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetHomeFeedUsecase].
final getHomeFeedUsecaseProvider = Provider<GetHomeFeedUsecase>((ref) {
  return GetHomeFeedUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère une page du fil de la page d'accueil, les contenus pas encore vus en tête.
///
/// Les contenus arrivent au gré des rencontres, sans que l'utilisateur les réclame : classés par le seul
/// `displayScore`, ils se perdraient au milieu de ceux qu'il connaît déjà. Dans chacun des deux groupes, l'ordre
/// reste celui du `displayScore`. Les contenus de l'utilisateur ne comptent jamais comme nouveaux : il les a écrits.
/// Un contenu est nouveau quand il n'est ni à l'utilisateur ni vu ([ContentDetailed.isViewed]).
///
/// Le fil est lu page par page, sur une session figée à [GetHomeFeedParams.feedStartedAt] : ce qui est vu ou reçu
/// pendant le défilement n'y apparaît qu'au rechargement, pour que les pages s'enchaînent sans doublon ni trou.
///
/// Ce use case est le point d'entrée générique de la home page : il ne prend aucun filtre en paramètre. Un futur
/// système de filtrage utilisateur passera par un use case dédié plutôt que par celui-ci.
class GetHomeFeedUsecase extends Usecase<GetHomeFeedParams, GetHomeFeedFailure, CursorPage<ContentDetailed>> {
  /// Crée un [GetHomeFeedUsecase].
  GetHomeFeedUsecase(this._contentRepository, this._errorLogRepository);

  /// Repository des contenus, qui assemble et pagine le fil.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<GetHomeFeedFailure, CursorPage<ContentDetailed>>> call(GetHomeFeedParams params) async {
    try {
      final page = await _contentRepository.getHomeFeedPage(
        feedStartedAt: params.feedStartedAt,
        after: params.after,
        limit: contentPageSize,
      );
      return Right(page);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetHomeFeedUsecase', error, stackTrace);
      return const Left(GetHomeFeedFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetHomeFeedUsecase', error, stackTrace);
      return const Left(GetHomeFeedFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetHomeFeedUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetHomeFeedUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetHomeFeedFailure.unknown);
    }
  }
}
