import 'package:bedbug/features/content/domain/repositories/viewed_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_viewed_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
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

/// Échecs possibles du [MarkContentViewedUsecase].
enum MarkContentViewedFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}

/// Paramètres du [MarkContentViewedUsecase].
class MarkContentViewedParams extends Params {
  /// Crée un [MarkContentViewedParams].
  ///
  /// - [contentId] : identifiant du contenu vu.
  const MarkContentViewedParams({required this.contentId});

  /// Identifiant du contenu vu.
  final String contentId;
}
