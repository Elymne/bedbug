import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content.entity.dart';
import 'package:bedbug/resources/content/content.repository.dart';
import 'package:bedbug/resources/content/content.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.failure.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentsBySignaturesUsecase].
final getContentsBySignaturesUsecaseProvider = Provider<GetContentsBySignaturesUsecase>((ref) {
  return GetContentsBySignaturesUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère tous les contenus signés par l'un des auteurs donnés.
///
/// Sert la recherche par nom de signature : plusieurs signatures peuvent
/// porter le même pseudo, et l'utilisateur veut voir ensemble tout ce qui a
/// été signé sous ce nom. Le domaine des contenus ne connaît pas les
/// signatures : c'est l'appelant qui fournit leurs identifiants. Un contenu
/// publié en anonyme porte l'identifiant anonyme, il n'apparaît donc jamais
/// sous le pseudo de son auteur réel.
///
/// Les résultats sont triés par `displayScore` décroissant, pour présenter
/// les contenus dans le même ordre de pertinence que la home page.
class GetContentsBySignaturesUsecase
    extends Usecase<GetContentsBySignaturesParams, GetContentsBySignaturesFailure, List<Content>> {
  /// Crée un [GetContentsBySignaturesUsecase].
  GetContentsBySignaturesUsecase(this._contentRepository, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetContentsBySignaturesFailure, List<Content>>> call(GetContentsBySignaturesParams params) async {
    try {
      if (params.signatureIds.isEmpty) {
        return const Right([]);
      }
      final contents = await _contentRepository.getAllBySignatures(params.signatureIds.toSet());
      contents.sort((first, second) => second.displayScore.compareTo(first.displayScore));
      return Right(contents);
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
