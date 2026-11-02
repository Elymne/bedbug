import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/comment/comment.repository.dart';
import 'package:bedbug/resources/content/comment/comment.repository.hive.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.repository.dart';
import 'package:bedbug/resources/content/storage/storage.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/content/clear_contents/clear_contents.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ClearContentsUsecase].
final clearContentsUsecaseProvider = Provider<ClearContentsUsecase>((ref) {
  return ClearContentsUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(commentRepositoryProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Supprime l'intégralité des contenus stockés localement, ainsi que leurs réactions et commentaires.
///
/// Les réactions et les commentaires sont stockés à part : sans ce nettoyage, ils resteraient
/// orphelins et continueraient d'occuper le stockage.
class ClearContentsUsecase extends Usecase<NoParams, ClearContentsFailure, void> {
  /// Crée un [ClearContentsUsecase].
  ClearContentsUsecase(
    this._contentRepository,
    this._storageRepository,
    this._reactionRepository,
    this._commentRepository,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;
  final ReactionRepository _reactionRepository;
  final CommentRepository _commentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<ClearContentsFailure, void>> call(NoParams params) async {
    try {
      await _contentRepository.deleteAll();
      await _reactionRepository.deleteAll();
      await _commentRepository.deleteAll();
      await _storageRepository.resetCurrentSizeInBytes();
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      return const Left(ClearContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      return const Left(ClearContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'ClearContentsUsecase', error: error, stackTrace: stackTrace);
      return const Left(ClearContentsFailure.unknown);
    }
  }
}
