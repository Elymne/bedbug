import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/domain/repositories/seen_content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [EnforceStorageLimitUsecase].
final enforceStorageLimitUsecaseProvider = Provider<EnforceStorageLimitUsecase>((ref) {
  return EnforceStorageLimitUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(commentRepositoryProvider),
    ref.read(seenContentRepositoryProvider),
  );
});

/// Ramène le poids des contenus sous la limite de stockage, et retourne le nombre de contenus supprimés.
///
/// Les échanges passifs ajoutent des contenus sans que l'utilisateur n'intervienne : sans ce nettoyage, ils
/// finiraient par remplir le téléphone. Les contenus reçus partent du plus faible `survivalScore` au plus fort, le
/// plus ancien d'abord à score égal. Les scores doivent donc être recalculés avant l'appel.
///
/// Les contenus de l'utilisateur ne sont jamais supprimés, même s'ils dépassent la limite à eux seuls : ce sont les
/// seuls qui n'existent peut-être nulle part ailleurs.
///
/// Les contenus supprimés sont mémorisés comme déjà vus : sinon, le prochain pair les renverrait aussitôt, pour un
/// nouveau nettoyage. Le poids réel, recalculé ici, corrige aussi un éventuel décalage du compteur de stockage.
class EnforceStorageLimitUsecase extends Usecase<NoParams, EnforceStorageLimitFailure, int> {
  /// Crée un [EnforceStorageLimitUsecase].
  EnforceStorageLimitUsecase(
    this._contentRepository,
    this._storageRepository,
    this._reactionRepository,
    this._commentRepository,
    this._seenContentRepository,
  );

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;
  final ReactionRepository _reactionRepository;
  final CommentRepository _commentRepository;
  final SeenContentRepository _seenContentRepository;

  @override
  Future<Either<EnforceStorageLimitFailure, int>> call(NoParams params) async {
    try {
      final storage = await _storageRepository.getUnique('');
      final limit = storage?.maxSizeInBytes ?? defaultMaxStorageSizeInBytes;
      final contents = await _contentRepository.getAll();

      var totalBytes = contents.fold<int>(0, (total, content) => total + content.sizeInBytes);
      final removedIds = <String>[];
      if (totalBytes > limit) {
        final candidates = contents.where((content) => !content.isOwned).toList()..sort(_compareSurvival);
        for (final content in candidates) {
          if (totalBytes <= limit) {
            break;
          }
          removedIds.add(content.id);
          totalBytes -= content.sizeInBytes;
        }
      }

      if (removedIds.isNotEmpty) {
        await _seenContentRepository.addMany(removedIds, DateTime.now());
        await _reactionRepository.deleteAllByContentIds(removedIds.toSet());
        await _commentRepository.deleteAllByContentIds(removedIds.toSet());
        await _contentRepository.deleteMany(removedIds);
      }

      final drift = totalBytes - (storage?.currentSizeInBytes ?? 0);
      if (drift != 0) {
        await _storageRepository.adjustCurrentSizeInBytes(drift);
      }

      return Right(removedIds.length);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('EnforceStorageLimitUsecase', error, stackTrace);
      return const Left(EnforceStorageLimitFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('EnforceStorageLimitUsecase', error, stackTrace);
      return const Left(EnforceStorageLimitFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('EnforceStorageLimitUsecase', error, stackTrace);
      return const Left(EnforceStorageLimitFailure.unknown);
    }
  }

  /// Classe [first] et [second] dans l'ordre de suppression.
  ///
  /// - [first] : premier contenu comparé.
  /// - [second] : second contenu comparé.
  int _compareSurvival(Content first, Content second) {
    final byScore = first.survivalScore.compareTo(second.survivalScore);
    return byScore != 0 ? byScore : first.createdAt.compareTo(second.createdAt);
  }
}

/// Échecs possibles du [EnforceStorageLimitUsecase].
enum EnforceStorageLimitFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du nettoyage.
  unknown,
}
