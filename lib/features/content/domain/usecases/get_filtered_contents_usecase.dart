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

/// Provider du [GetFilteredContentsUsecase].
final getFilteredContentsUsecaseProvider = Provider<GetFilteredContentsUsecase>((ref) {
  return GetFilteredContentsUsecase(ref.read(contentRepositoryProvider));
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
  GetFilteredContentsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

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
      return const Left(GetFilteredContentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetFilteredContentsUsecase].
enum GetFilteredContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}

/// Paramètres du [GetFilteredContentsUsecase].
class GetFilteredContentsParams extends Params {
  /// Crée des [GetFilteredContentsParams].
  ///
  /// - [query] : texte saisi par l'utilisateur, comparé au titre et au flair des contenus.
  const GetFilteredContentsParams({required this.query});

  /// Texte saisi par l'utilisateur, comparé au titre et au flair des contenus.
  final String query;
}
