import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentsByFlairUsecase].
final getContentsByFlairUsecaseProvider = Provider<GetContentsByFlairUsecase>(
  (ref) => GetContentsByFlairUsecase(ref.read(contentRepositoryProvider)),
);

/// Récupère tous les contenus rattachés à un flair précis.
///
/// Sert la page de résultats ouverte quand l'utilisateur choisit un flair
/// parmi les suggestions d'autocomplétion : son intention est alors
/// explicite (« montre-moi /france »), on retourne donc uniquement les
/// contenus de ce flair exact, sans la correspondance approximative de la
/// recherche globale.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter
/// les contenus dans le même ordre de pertinence que la home page.
class GetContentsByFlairUsecase extends Usecase<GetContentsByFlairParams, GetContentsByFlairFailure, List<Content>> {
  /// Crée un [GetContentsByFlairUsecase].
  GetContentsByFlairUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<GetContentsByFlairFailure, List<Content>>> call(GetContentsByFlairParams params) async {
    try {
      final flair = params.flair.toFlair();
      if (flair == null) {
        return const Right([]);
      }

      final contents = await _contentRepository.getAllByFlair(flair);
      contents.sort((first, second) => second.displayScore.compareTo(first.displayScore));
      return Right(contents);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentsByFlairUsecase', error, stackTrace);
      return const Left(GetContentsByFlairFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentsByFlairUsecase', error, stackTrace);
      return const Left(GetContentsByFlairFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentsByFlairUsecase', error, stackTrace);
      return const Left(GetContentsByFlairFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetContentsByFlairUsecase].
enum GetContentsByFlairFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}

/// Paramètres du [GetContentsByFlairUsecase].
class GetContentsByFlairParams extends Params {
  /// Crée des [GetContentsByFlairParams].
  ///
  /// - [flair] : flair recherché, avec ou sans `/` initial (normalisé par le use case).
  const GetContentsByFlairParams({required this.flair});

  /// Flair recherché, avec ou sans `/` initial.
  final String flair;
}
