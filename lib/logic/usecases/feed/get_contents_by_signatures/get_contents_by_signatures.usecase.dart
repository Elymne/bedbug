import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.config.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentsBySignaturesUsecase].
final getContentsBySignaturesUsecaseProvider = Provider<GetContentsBySignaturesUsecase>((ref) {
  return GetContentsBySignaturesUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère une page des contenus signés par l'un des auteurs donnés.
///
/// Sert la recherche par nom de signature : plusieurs signatures peuvent porter le même pseudo, et l'utilisateur veut
/// voir ensemble tout ce qui a été signé sous ce nom. C'est l'appelant qui fournit les identifiants des signatures.
/// Un contenu publié en anonyme porte l'identifiant anonyme, il n'apparaît donc jamais sous le pseudo de son auteur
/// réel.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter les contenus dans le même ordre de
/// pertinence que la home page, et lus page par page.
class GetContentsBySignaturesUsecase
    extends Usecase<GetContentsBySignaturesParams, GetContentsBySignaturesFailure, CursorPage<ContentDetailed>> {
  /// Crée un [GetContentsBySignaturesUsecase].
  GetContentsBySignaturesUsecase(this._contentRepository, this._errorLogRepository);

  /// Repository des contenus.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<GetContentsBySignaturesFailure, CursorPage<ContentDetailed>>> call(
    GetContentsBySignaturesParams params,
  ) async {
    try {
      if (params.signatureIds.isEmpty) {
        return const Right(CursorPage(items: [], nextCursor: null));
      }
      final page = await _contentRepository.getPageBySignatures(
        params.signatureIds.toSet(),
        after: params.after,
        limit: contentPageSize,
      );
      return Right(page);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentsBySignaturesUsecase', error, stackTrace);
      return const Left(GetContentsBySignaturesFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentsBySignaturesUsecase', error, stackTrace);
      return const Left(GetContentsBySignaturesFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentsBySignaturesUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetContentsBySignaturesUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetContentsBySignaturesFailure.unknown);
    }
  }
}
