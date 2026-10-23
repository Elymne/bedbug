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

/// Provider du [GetContentsByAuthorUsecase].
final getContentsByAuthorUsecaseProvider = Provider<GetContentsByAuthorUsecase>(
  (ref) => GetContentsByAuthorUsecase(ref.read(contentRepositoryProvider)),
);

/// Récupère tous les contenus signés par un auteur précis.
///
/// Sert la page de résultats ouverte quand l'utilisateur choisit un auteur
/// parmi les suggestions de recherche : il veut voir ce que cette personne a
/// publié. Seuls les contenus portant exactement cet identifiant d'auteur
/// sont retournés : un contenu publié en anonyme porte l'identifiant
/// anonyme, il n'apparaît donc jamais sous le pseudo de son auteur réel.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter
/// les contenus dans le même ordre de pertinence que la home page.
class GetContentsByAuthorUsecase extends Usecase<GetContentsByAuthorParams, GetContentsByAuthorFailure, List<Content>> {
  /// Crée un [GetContentsByAuthorUsecase].
  GetContentsByAuthorUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<GetContentsByAuthorFailure, List<Content>>> call(GetContentsByAuthorParams params) async {
    try {
      final contents = await _contentRepository.getAllByAuthor(params.authorId);
      contents.sort((first, second) => second.displayScore.compareTo(first.displayScore));
      return Right(contents);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentsByAuthorUsecase', error, stackTrace);
      return const Left(GetContentsByAuthorFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentsByAuthorUsecase', error, stackTrace);
      return const Left(GetContentsByAuthorFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentsByAuthorUsecase', error, stackTrace);
      return const Left(GetContentsByAuthorFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetContentsByAuthorUsecase].
enum GetContentsByAuthorFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}

/// Paramètres du [GetContentsByAuthorUsecase].
class GetContentsByAuthorParams extends Params {
  /// Crée des [GetContentsByAuthorParams].
  ///
  /// - [authorId] : identifiant de l'auteur dont on veut les contenus.
  const GetContentsByAuthorParams({required this.authorId});

  /// Identifiant de l'auteur dont on veut les contenus.
  final String authorId;
}
