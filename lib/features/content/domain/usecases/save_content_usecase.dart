import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveContentUsecase].
final saveContentUsecaseProvider = Provider<SaveContentUsecase>(
  (ref) => SaveContentUsecase(ref.read(contentRepositoryProvider)),
);

/// Persiste un contenu dans le stockage local.
class SaveContentUsecase extends Usecase<SaveContentParams, SaveContentFailure, Content> {
  /// Crée un [SaveContentUsecase].
  SaveContentUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<SaveContentFailure, Content>> call(SaveContentParams params) async {
    try {
      final content = await _contentRepository.addOne(params.content);
      return Right(content);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      return const Left(SaveContentFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      return const Left(SaveContentFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveContentUsecase].
enum SaveContentFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la sauvegarde.
  unknown,
}

/// Paramètres du [SaveContentUsecase].
class SaveContentParams extends Params {
  /// Crée des [SaveContentParams].
  ///
  /// - [content] : entité à persister.
  const SaveContentParams({required this.content});

  /// Contenu à persister.
  final Content content;
}
