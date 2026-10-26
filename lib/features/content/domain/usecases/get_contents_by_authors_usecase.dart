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

/// Provider du [GetContentsByAuthorsUsecase].
final getContentsByAuthorsUsecaseProvider = Provider<GetContentsByAuthorsUsecase>((ref) {
  return GetContentsByAuthorsUsecase(ref.read(contentRepositoryProvider));
});

/// Récupère tous les contenus signés par l'un des auteurs donnés.
///
/// Sert la recherche par nom de signature : plusieurs signatures peuvent
/// porter le même pseudo, et l'utilisateur veut voir ensemble tout ce qui a
/// été signé sous ce nom. Le domaine des contenus ne connaît pas les
/// signatures : c'est l'appelant qui fournit leurs identifiants. Un contenu
/// publié en anonyme porte l'identifiant anonyme, il n'apparaît donc jamais
/// sous le pseudo de son auteur réel.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter
/// les contenus dans le même ordre de pertinence que la home page.
class GetContentsByAuthorsUsecase
    extends Usecase<GetContentsByAuthorsParams, GetContentsByAuthorsFailure, List<Content>> {
  /// Crée un [GetContentsByAuthorsUsecase].
  GetContentsByAuthorsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<GetContentsByAuthorsFailure, List<Content>>> call(GetContentsByAuthorsParams params) async {
    try {
      if (params.authorIds.isEmpty) {
        return const Right([]);
      }
      final contents = await _contentRepository.getAllByAuthors(params.authorIds.toSet());
      contents.sort((first, second) => second.displayScore.compareTo(first.displayScore));
      return Right(contents);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentsByAuthorsUsecase', error, stackTrace);
      return const Left(GetContentsByAuthorsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentsByAuthorsUsecase', error, stackTrace);
      return const Left(GetContentsByAuthorsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentsByAuthorsUsecase', error, stackTrace);
      return const Left(GetContentsByAuthorsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetContentsByAuthorsUsecase].
enum GetContentsByAuthorsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}

/// Paramètres du [GetContentsByAuthorsUsecase].
class GetContentsByAuthorsParams extends Params {
  /// Crée des [GetContentsByAuthorsParams].
  ///
  /// - [authorIds] : identifiants des auteurs dont on veut les contenus.
  const GetContentsByAuthorsParams({required this.authorIds});

  /// Identifiants des auteurs dont on veut les contenus.
  final List<String> authorIds;
}
