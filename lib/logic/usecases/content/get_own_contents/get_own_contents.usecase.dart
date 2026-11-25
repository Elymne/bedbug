import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/content/get_own_contents/get_own_contents.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetOwnContentsUsecase].
final getOwnContentsUsecaseProvider = Provider<GetOwnContentsUsecase>((ref) {
  return GetOwnContentsUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère les contenus créés sur cet appareil par son utilisateur, anonymes compris.
///
/// L'utilisateur doit pouvoir retrouver tout ce qu'il a publié pour le relire ou le supprimer, y compris ses posts
/// anonymes (qu'aucune recherche par auteur ne lui rattache). Les contenus sont triés du plus récent au plus ancien :
/// c'est l'historique de ses publications, pas un fil classé par pertinence.
///
/// Non paginé : la liste est affichée en entier dans les paramètres, et ne compte que ce que l'utilisateur a écrit.
class GetOwnContentsUsecase extends Usecase<NoParams, GetOwnContentsFailure, List<ContentDetailed>> {
  /// Crée un [GetOwnContentsUsecase].
  GetOwnContentsUsecase(this._contentRepository, this._errorLogRepository);

  /// Repository des contenus.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<GetOwnContentsFailure, List<ContentDetailed>>> call(NoParams params) async {
    try {
      return Right(await _contentRepository.getAllDetailedByOrigin(ContentOrigin.owned));
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetOwnContentsUsecase', error, stackTrace);
      return const Left(GetOwnContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetOwnContentsUsecase', error, stackTrace);
      return const Left(GetOwnContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetOwnContentsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetOwnContentsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetOwnContentsFailure.unknown);
    }
  }
}
