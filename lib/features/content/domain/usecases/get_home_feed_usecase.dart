import 'package:bedbug/features/content/domain/object_values/home_feed.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/viewed_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_viewed_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetHomeFeedUsecase].
final getHomeFeedUsecaseProvider = Provider<GetHomeFeedUsecase>((ref) {
  return GetHomeFeedUsecase(ref.read(contentRepositoryProvider), ref.read(viewedContentRepositoryProvider));
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
  GetHomeFeedUsecase(this._contentRepository, this._viewedContentRepository);

  final ContentRepository _contentRepository;
  final ViewedContentRepository _viewedContentRepository;

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
      return const Left(GetHomeFeedFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetHomeFeedUsecase].
enum GetHomeFeedFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}
