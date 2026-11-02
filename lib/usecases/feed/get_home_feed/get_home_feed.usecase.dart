import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content.repository.dart';
import 'package:bedbug/resources/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/home_feed.value_object.dart';
import 'package:bedbug/resources/content/viewed_content.repository.dart';
import 'package:bedbug/resources/content/viewed_content.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetHomeFeedUsecase].
final getHomeFeedUsecaseProvider = Provider<GetHomeFeedUsecase>((ref) {
  return GetHomeFeedUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(viewedContentRepositoryProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Récupère le flux de contenus de la page d'accueil, les contenus pas encore vus en tête.
///
/// Les contenus arrivent au gré des rencontres, sans que l'utilisateur les réclame : classés par le seul
/// `displayScore`, ils se perdraient au milieu de ceux qu'il connaît déjà. Dans chacun des deux groupes, l'ordre
/// reste celui du `displayScore`. Les contenus de l'utilisateur ne comptent jamais comme nouveaux : il les a écrits.
///
/// Ce use case est le point d'entrée générique de la home page : il ne prend aucun filtre en paramètre. Un futur
/// système de filtrage utilisateur passera par un use case dédié plutôt que par celui-ci.
class GetHomeFeedUsecase extends Usecase<NoParams, GetHomeFeedFailure, HomeFeed> {
  /// Crée un [GetHomeFeedUsecase].
  GetHomeFeedUsecase(this._contentRepository, this._viewedContentRepository, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final ViewedContentRepository _viewedContentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetHomeFeedFailure, HomeFeed>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAllOrderedByDisplayScoreDesc();
      final viewedIds = await _viewedContentRepository.getAllIds();
      final unviewed = contents.where((content) => !content.isOwned && !viewedIds.contains(content.id)).toList();
      final unviewedIds = unviewed.map((content) => content.id).toSet();
      final others = contents.where((content) => !unviewedIds.contains(content.id));
      return Right(HomeFeed(contents: [...unviewed, ...others], unviewedContentIds: unviewedIds));
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
