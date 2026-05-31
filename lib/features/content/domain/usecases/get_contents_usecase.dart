import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/exceptions/page_not_found_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:bedbug/shared/domain/order_by.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentsUsecase].
final getContentsUsecaseProvider = Provider<GetContentsUsecase>(
  (ref) => GetContentsUsecase(ref.read(contentRepositoryProvider)),
);

/// Récupère tous les contenus, triés du plus récent au plus ancien par défaut.
class GetContentsUsecase extends Usecase<GetContentsParams, GetContentsFailure, List<Content>> {
  /// Crée un [GetContentsUsecase].
  GetContentsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<GetContentsFailure, List<Content>>> call(GetContentsParams params) async {
    try {
      final page = await _contentRepository.getMany(
        ContentRepositoryParams(orderBy: params.orderBy),
      );
      return Right(page.items);
    } on PageNotFoundException catch (error, stackTrace) {
      AppLogger.error('GetContentsUsecase', error, stackTrace);
      return const Left(GetContentsFailure.pageNotFound);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentsUsecase', error, stackTrace);
      return const Left(GetContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentsUsecase', error, stackTrace);
      return const Left(GetContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentsUsecase', error, stackTrace);
      return const Left(GetContentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetContentsUsecase].
enum GetContentsFailure {
  /// La page demandée n'existe pas.
  pageNotFound,

  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}

/// Paramètres du [GetContentsUsecase].
class GetContentsParams extends Params {
  /// Crée des [GetContentsParams].
  ///
  /// - [orderBy] : tri appliqué aux résultats. Par défaut, du plus récent
  ///   au plus ancien.
  const GetContentsParams({this.orderBy = const OrderBy('createdAt', descending: true)});

  /// Tri appliqué aux résultats.
  final OrderBy orderBy;
}
