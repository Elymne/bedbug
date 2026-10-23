import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetOwnContentsUsecase].
final getOwnContentsUsecaseProvider = Provider<GetOwnContentsUsecase>(
  (ref) => GetOwnContentsUsecase(ref.read(contentRepositoryProvider)),
);

/// Récupère les contenus créés sur cet appareil par son utilisateur, anonymes compris.
///
/// L'utilisateur doit pouvoir retrouver tout ce qu'il a publié pour le
/// relire ou le supprimer, y compris ses posts anonymes (qu'aucune recherche
/// par auteur ne lui rattache). Les contenus sont triés du plus récent au
/// plus ancien : c'est l'historique de ses publications, pas un fil classé
/// par pertinence.
class GetOwnContentsUsecase extends Usecase<NoParams, GetOwnContentsFailure, List<Content>> {
  /// Crée un [GetOwnContentsUsecase].
  GetOwnContentsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

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
      return const Left(GetOwnContentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetOwnContentsUsecase].
enum GetOwnContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}
