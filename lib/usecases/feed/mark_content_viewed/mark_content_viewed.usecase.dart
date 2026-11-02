import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/viewed_content.repository.dart';
import 'package:bedbug/resources/content/viewed_content.repository.hive.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/usecases/feed/mark_content_viewed/mark_content_viewed.failure.dart';
import 'package:bedbug/usecases/feed/mark_content_viewed/mark_content_viewed.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [MarkContentViewedUsecase].
final markContentViewedUsecaseProvider = Provider<MarkContentViewedUsecase>((ref) {
  return MarkContentViewedUsecase(ref.read(viewedContentRepositoryProvider));
});

/// Mémorise qu'un contenu est passé sous les yeux de l'utilisateur.
///
/// Le fil d'accueil remonte ce qui n'a pas encore été vu : sans cette mémoire, un contenu resterait « nouveau » pour
/// toujours, et les mêmes occuperaient indéfiniment le haut de la liste.
class MarkContentViewedUsecase extends Usecase<MarkContentViewedParams, MarkContentViewedFailure, void> {
  /// Crée un [MarkContentViewedUsecase].
  MarkContentViewedUsecase(this._viewedContentRepository);

  final ViewedContentRepository _viewedContentRepository;

  @override
  Future<Either<MarkContentViewedFailure, void>> call(MarkContentViewedParams params) async {
    try {
      await _viewedContentRepository.add(params.contentId);
      return const Right(null);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('MarkContentViewedUsecase', error, stackTrace);
      return const Left(MarkContentViewedFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('MarkContentViewedUsecase', error, stackTrace);
      return const Left(MarkContentViewedFailure.unknown);
    }
  }
}
