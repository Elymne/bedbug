import 'dart:convert';
import 'dart:io';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/config/content_image_storage.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider du [SaveContentUsecase].
final saveContentUsecaseProvider = Provider<SaveContentUsecase>(
  (ref) => SaveContentUsecase(ref.read(contentRepositoryProvider), ref.read(storageRepositoryProvider)),
);

/// Persiste un contenu dans le stockage local.
///
/// Le poids (`sizeInBytes`) fourni par l'appelant n'est pas fiable — un
/// contenu reçu d'un pair pourrait mentir sur sa taille pour échapper aux
/// limites de stockage. Ce use case détermine donc lui-même le poids réel
/// avant persistance plutôt que de faire confiance à la valeur du contenu
/// passé en paramètre.
class SaveContentUsecase extends Usecase<SaveContentParams, SaveContentFailure, Content> {
  /// Crée un [SaveContentUsecase].
  SaveContentUsecase(this._contentRepository, this._storageRepository);

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;

  @override
  Future<Either<SaveContentFailure, Content>> call(SaveContentParams params) async {
    try {
      final sizeInBytes = await _computeSizeInBytes(params.content);
      final resized = params.content.copyWithSizeInBytes(sizeInBytes);

      final content = await _contentRepository.addOne(resized);
      await _storageRepository.adjustCurrentSizeInBytes(content.sizeInBytes);
      return Right(content);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      return const Left(SaveContentFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      return const Left(SaveContentFailure.unknown);
    }
  }

  /// Détermine le poids réel de [content], selon son type concret.
  ///
  /// - [TextContent]/[LinkContent] : somme des octets UTF-8 de leurs champs
  ///   texte, calculable directement depuis les données du domaine.
  /// - [ImageContent] : taille du fichier image sur disque, seule mesure
  ///   fidèle au poids effectivement occupé sur l'appareil.
  Future<int> _computeSizeInBytes(Content content) async {
    if (content is TextContent) {
      return utf8.encode(content.title).length + utf8.encode(content.body).length;
    }

    if (content is LinkContent) {
      final fields = [
        content.title,
        content.url,
        content.body,
        content.ogTitle,
        content.ogDescription,
        content.ogImageUrl,
      ];
      return fields.whereType<String>().fold<int>(0, (total, field) => total + utf8.encode(field).length);
    }

    if (content is ImageContent) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$contentImagesFolder/${content.fileName}');
      if (!file.existsSync()) {
        return 0;
      }
      return file.lengthSync();
    }

    return content.sizeInBytes;
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
