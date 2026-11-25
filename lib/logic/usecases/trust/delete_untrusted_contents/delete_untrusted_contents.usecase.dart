import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.config.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.repository.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.repository.drift.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.failure.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.params.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.service.dart';
import 'package:bedbug/logic/usecases/trust/delete_untrusted_contents/delete_untrusted_contents.failure.dart';
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
  ///
  /// - [_contentRepository] : lecture des adresses des contenus reçus.
  /// - [_trustSettingsRepository] : lecture des listes de domaines de l'utilisateur.
  /// - [_deleteContentsService] : suppression des contenus refusés, avec tout ce qui leur est rattaché.
  /// - [_errorLogRepository] : journal des erreurs inattendues.
  DeleteUntrustedContentsUsecase(
    this._contentRepository,
    this._trustSettingsRepository,
    this._deleteContentsService,
    this._errorLogRepository,
  );

  /// Lecture des adresses des contenus reçus.
  final ContentRepository _contentRepository;

  /// Lecture des listes de domaines de l'utilisateur.
  final TrustSettingsRepository _trustSettingsRepository;

  /// Suppression des contenus refusés, avec tout ce qui leur est rattaché.
  final DeleteContentsService _deleteContentsService;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Supprime les contenus reçus dont une adresse n'est acceptée par aucune liste, et retourne leur nombre.
  ///
  /// Seules les adresses des contenus reçus qui en ont sont lues : la règle de confiance s'applique en Dart, sur
  /// les domaines, ce que SQL ne sait pas faire.
  ///
  /// - [params] : aucun paramètre.
  @override
  Future<Either<DeleteUntrustedContentsFailure, int>> call(NoParams params) async {
    try {
      final settings = await _trustSettingsRepository.get() ?? defaultTrustSettings;
      final summaries = await _contentRepository.getReceivedUrlSummaries();
      final untrustedIds = [
        for (final summary in summaries)
          if (TrustSettings.isContentHidden(settings, mediaUrls: summary.mediaUrls, linkUrls: summary.linkUrls))
            summary.contentId,
      ];

      final result = await _deleteContentsService(DeleteContentsParams(contentIds: untrustedIds));
      return result.fold<Either<DeleteUntrustedContentsFailure, int>>(
        onFailure: (DeleteContentsFailure failure) => Left(switch (failure) {
          DeleteContentsFailure.storageError => DeleteUntrustedContentsFailure.storageError,
          DeleteContentsFailure.unknown => DeleteUntrustedContentsFailure.unknown,
        }),
        onSuccess: (_) => Right(untrustedIds.length),
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
