import 'package:bedbug/features/content/domain/extensions/content_urls_extension.dart';
import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/domain/repositories/seen_content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/repositories/trust_settings_repository.dart';
import 'package:bedbug/features/content/domain/repositories/viewed_content_repository.dart';
import 'package:bedbug/features/content/domain/services/url_trust_service.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_trust_settings_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_viewed_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DeleteUntrustedContentsUsecase].
final deleteUntrustedContentsUsecaseProvider = Provider<DeleteUntrustedContentsUsecase>((ref) {
  return DeleteUntrustedContentsUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(trustSettingsRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(commentRepositoryProvider),
    ref.read(seenContentRepositoryProvider),
    ref.read(viewedContentRepositoryProvider),
    ref.read(urlTrustServiceProvider),
  );
});

/// Supprime du téléphone les contenus reçus qui pointent vers un domaine absent des listes de l'utilisateur, et
/// retourne le nombre de contenus supprimés.
///
/// Le téléphone ne doit ni garder ni relayer ce que son utilisateur n'a pas accepté : masquer ces contenus ne suffirait
/// pas, ils continueraient d'occuper le stockage et d'être proposés aux pairs. Les listes changent à la réception
/// d'un contenu comme à la main de l'utilisateur : ce use case est donc appelé après chaque échange, après chaque
/// modification des listes, et au démarrage.
///
/// Les contenus de l'utilisateur ne sont jamais supprimés : ce sont les seuls qui n'existent peut-être nulle part
/// ailleurs. Si les listes ne peuvent pas être lues, rien n'est supprimé : une panne de lecture ne doit pas vider le
/// téléphone.
///
/// Les contenus supprimés sont mémorisés comme déjà vus : sinon, le prochain pair les renverrait aussitôt, pour une
/// nouvelle suppression.
class DeleteUntrustedContentsUsecase extends Usecase<NoParams, DeleteUntrustedContentsFailure, int> {
  /// Crée un [DeleteUntrustedContentsUsecase].
  DeleteUntrustedContentsUsecase(
    this._contentRepository,
    this._trustSettingsRepository,
    this._storageRepository,
    this._reactionRepository,
    this._commentRepository,
    this._seenContentRepository,
    this._viewedContentRepository,
    this._urlTrustService,
  );

  final ContentRepository _contentRepository;
  final TrustSettingsRepository _trustSettingsRepository;
  final StorageRepository _storageRepository;
  final ReactionRepository _reactionRepository;
  final CommentRepository _commentRepository;
  final SeenContentRepository _seenContentRepository;
  final ViewedContentRepository _viewedContentRepository;
  final UrlTrustService _urlTrustService;

  @override
  Future<Either<DeleteUntrustedContentsFailure, int>> call(NoParams params) async {
    try {
      final settings = await _trustSettingsRepository.get() ?? defaultTrustSettings;
      final contents = await _contentRepository.getAll();
      final untrusted = contents.where((content) {
        return !content.isOwned &&
            _urlTrustService.isContentHidden(settings, mediaUrls: content.mediaUrls, linkUrls: content.linkUrls);
      }).toList();
      if (untrusted.isEmpty) {
        return const Right(0);
      }

      final ids = untrusted.map((content) => content.id).toList();
      await _seenContentRepository.addMany(ids, DateTime.now());
      await _viewedContentRepository.deleteMany(ids);
      await _reactionRepository.deleteAllByContentIds(ids.toSet());
      await _commentRepository.deleteAllByContentIds(ids.toSet());
      await _contentRepository.deleteMany(ids);
      final freedBytes = untrusted.fold<int>(0, (total, content) => total + content.sizeInBytes);
      await _storageRepository.adjustCurrentSizeInBytes(-freedBytes);
      return Right(ids.length);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('DeleteUntrustedContentsUsecase', error, stackTrace);
      return const Left(DeleteUntrustedContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('DeleteUntrustedContentsUsecase', error, stackTrace);
      return const Left(DeleteUntrustedContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('DeleteUntrustedContentsUsecase', error, stackTrace);
      return const Left(DeleteUntrustedContentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [DeleteUntrustedContentsUsecase].
enum DeleteUntrustedContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la suppression.
  unknown,
}
