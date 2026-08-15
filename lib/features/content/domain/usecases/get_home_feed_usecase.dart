import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetHomeFeedUsecase].
final getHomeFeedUsecaseProvider = Provider<GetHomeFeedUsecase>(
  (ref) => GetHomeFeedUsecase(ref.read(contentRepositoryProvider)),
);

/// Récupère le flux de contenus de la page d'accueil, classé par les
/// algorithmes de scoring de l'application.
///
/// Ce use case est le point d'entrée générique de la home page : il ne
/// prend aucun filtre en paramètre, la sélection et l'ordre affichés sont
/// entièrement déterminés par `displayScore`. Un futur système de filtrage
/// utilisateur passera par un use case dédié plutôt que par celui-ci.
class GetHomeFeedUsecase extends Usecase<NoParams, GetHomeFeedFailure, List<Content>> {
  /// Crée un [GetHomeFeedUsecase].
  GetHomeFeedUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<GetHomeFeedFailure, List<Content>>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAllOrderedByDisplayScoreDesc();
      return Right(contents);
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
