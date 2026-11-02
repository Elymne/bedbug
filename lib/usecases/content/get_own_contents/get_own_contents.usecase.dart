import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content.entity.dart';
import 'package:bedbug/resources/content/content.repository.dart';
import 'package:bedbug/resources/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/content_origin.enum.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/content/get_own_contents/get_own_contents.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetOwnContentsUsecase].
final getOwnContentsUsecaseProvider = Provider<GetOwnContentsUsecase>((ref) {
  return GetOwnContentsUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère les contenus créés sur cet appareil par son utilisateur, anonymes compris.
///
/// L'utilisateur doit pouvoir retrouver tout ce qu'il a publié pour le
/// relire ou le supprimer, y compris ses posts anonymes (qu'aucune recherche
/// par auteur ne lui rattache). Les contenus sont triés du plus récent au
/// plus ancien : c'est l'historique de ses publications, pas un fil classé
/// par pertinence.
class GetOwnContentsUsecase extends Usecase<NoParams, GetOwnContentsFailure, List<Content>> {
  /// Crée un [GetOwnContentsUsecase].
  GetOwnContentsUsecase(this._contentRepository, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetOwnContentsFailure, List<Content>>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAllByOrigin(ContentOrigin.owned);
      contents.sort((first, second) => second.createdAt.compareTo(first.createdAt));
      return Right(contents);
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
