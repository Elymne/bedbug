import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content/content.extension.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.config.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.repository.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.repository.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.failure.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.params.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.service.dart';
import 'package:bedbug/usecases/trust/delete_untrusted_contents/delete_untrusted_contents.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DeleteUntrustedContentsUsecase].
final deleteUntrustedContentsUsecaseProvider = Provider<DeleteUntrustedContentsUsecase>((ref) {
  return DeleteUntrustedContentsUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(trustSettingsRepositoryProvider),
    ref.read(deleteContentsServiceProvider),
    ref.read(errorLogRepositoryProvider),
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
/// La suppression passe par [DeleteContentsService] : les contenus supprimés sont notamment mémorisés comme déjà vus,
/// sans quoi le prochain pair les renverrait aussitôt, pour une nouvelle suppression.
class DeleteUntrustedContentsUsecase extends Usecase<NoParams, DeleteUntrustedContentsFailure, int> {
  /// Crée un [DeleteUntrustedContentsUsecase].
  DeleteUntrustedContentsUsecase(
    this._contentRepository,
    this._trustSettingsRepository,
    this._deleteContentsService,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final TrustSettingsRepository _trustSettingsRepository;
  final DeleteContentsService _deleteContentsService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<DeleteUntrustedContentsFailure, int>> call(NoParams params) async {
    try {
      final settings = await _trustSettingsRepository.get() ?? defaultTrustSettings;
      final contents = await _contentRepository.getAll();
      final untrusted = contents.where((content) {
        return !content.isOwned &&
            TrustSettings.isContentHidden(settings, mediaUrls: content.mediaUrls, linkUrls: content.linkUrls);
      }).toList();

      final result = await _deleteContentsService(DeleteContentsParams(contents: untrusted));
      return result.fold<Either<DeleteUntrustedContentsFailure, int>>(
        onFailure: (DeleteContentsFailure failure) => Left(switch (failure) {
          DeleteContentsFailure.storageError => DeleteUntrustedContentsFailure.storageError,
          DeleteContentsFailure.unknown => DeleteUntrustedContentsFailure.unknown,
        }),
        onSuccess: (_) => Right(untrusted.length),
      );
    } on DataException catch (error, stackTrace) {
      AppLogger.error('DeleteUntrustedContentsUsecase', error, stackTrace);
      return const Left(DeleteUntrustedContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('DeleteUntrustedContentsUsecase', error, stackTrace);
      return const Left(DeleteUntrustedContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('DeleteUntrustedContentsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'DeleteUntrustedContentsUsecase', error: error, stackTrace: stackTrace);
      return const Left(DeleteUntrustedContentsFailure.unknown);
    }
  }
}
