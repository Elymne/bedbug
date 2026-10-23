import 'dart:io';

import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/config/content_image_storage.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider du [DeleteOwnContentUsecase].
final deleteOwnContentUsecaseProvider = Provider<DeleteOwnContentUsecase>(
  (ref) => DeleteOwnContentUsecase(ref.read(contentRepositoryProvider), ref.read(storageRepositoryProvider)),
);

/// Supprime de l'appareil un contenu que son utilisateur a lui-même publié.
///
/// Permet de retirer un post regretté avant qu'il ne se propage. Seuls les
/// contenus créés sur cet appareil (`isOwned`) peuvent être supprimés ainsi :
/// un contenu reçu d'un pair n'appartient pas à l'utilisateur, il disparaîtra
/// selon les règles de nettoyage du stockage. La suppression est locale : les
/// copies déjà transmises à d'autres appareils ne peuvent pas être rappelées.
///
/// Le fichier image d'un [ImageContent] est supprimé avec lui, et le poids du
/// contenu est retiré du compteur de stockage.
class DeleteOwnContentUsecase extends Usecase<DeleteOwnContentParams, DeleteOwnContentFailure, void> {
  /// Crée un [DeleteOwnContentUsecase].
  DeleteOwnContentUsecase(this._contentRepository, this._storageRepository);

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;

  @override
  Future<Either<DeleteOwnContentFailure, void>> call(DeleteOwnContentParams params) async {
    try {
      final content = await _contentRepository.getById(params.contentId);
      if (content == null) {
        return const Left(DeleteOwnContentFailure.notFound);
      }
      if (!content.isOwned) {
        return const Left(DeleteOwnContentFailure.notOwned);
      }

      await _contentRepository.deleteOne(content.id);
      await _storageRepository.adjustCurrentSizeInBytes(-content.sizeInBytes);

      if (content is ImageContent) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$contentImagesFolder/${content.fileName}');
        if (file.existsSync()) {
          await file.delete();
        }
      }
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('DeleteOwnContentUsecase', error, stackTrace);
      return const Left(DeleteOwnContentFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('DeleteOwnContentUsecase', error, stackTrace);
      return const Left(DeleteOwnContentFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('DeleteOwnContentUsecase', error, stackTrace);
      return const Left(DeleteOwnContentFailure.unknown);
    }
  }
}

/// Échecs possibles du [DeleteOwnContentUsecase].
enum DeleteOwnContentFailure {
  /// Aucun contenu ne porte cet identifiant (déjà supprimé, par exemple).
  notFound,

  /// Le contenu n'a pas été créé sur cet appareil : sa suppression est refusée.
  notOwned,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la suppression.
  unknown,
}

/// Paramètres du [DeleteOwnContentUsecase].
class DeleteOwnContentParams extends Params {
  /// Crée des [DeleteOwnContentParams].
  ///
  /// - [contentId] : identifiant du contenu à supprimer.
  const DeleteOwnContentParams({required this.contentId});

  /// Identifiant du contenu à supprimer.
  final String contentId;
}
