import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content.entity.dart';
import 'package:bedbug/resources/content/content.repository.dart';
import 'package:bedbug/resources/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/flair.extension.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/usecases/feed/get_contents_by_flair/get_contents_by_flair.failure.dart';
import 'package:bedbug/usecases/feed/get_contents_by_flair/get_contents_by_flair.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentsByFlairUsecase].
final getContentsByFlairUsecaseProvider = Provider<GetContentsByFlairUsecase>((ref) {
  return GetContentsByFlairUsecase(ref.read(contentRepositoryProvider));
});

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
