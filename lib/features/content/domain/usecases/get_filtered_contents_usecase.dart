import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetFilteredContentsUsecase].
final getFilteredContentsUsecaseProvider = Provider<GetFilteredContentsUsecase>(
  (ref) => GetFilteredContentsUsecase(ref.read(contentRepositoryProvider)),
);

/// Récupère les contenus dont le titre correspond à une recherche utilisateur.
///
/// Ce use case sert la vue de recherche (barre de recherche dédiée), dont le
/// besoin diffère de celui de la home page : ici, l'utilisateur fournit
/// volontairement un critère de filtrage, alors que le use case de flux de
/// la home page retourne un flux non filtré ordonné par score. Les deux évolueront
/// indépendamment (nouveaux critères de filtre ici, nouveaux facteurs de
/// scoring là-bas), d'où leur séparation en use cases distincts.
class GetFilteredContentsUsecase extends Usecase<GetFilteredContentsParams, GetFilteredContentsFailure, List<Content>> {
  /// Crée un [GetFilteredContentsUsecase].
  GetFilteredContentsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<GetFilteredContentsFailure, List<Content>>> call(GetFilteredContentsParams params) async {
    try {
      final contents = await _contentRepository.getAllMatchingTitle(params.query);
      return Right(contents);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetFilteredContentsUsecase', error, stackTrace);
      return const Left(GetFilteredContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetFilteredContentsUsecase', error, stackTrace);
      return const Left(GetFilteredContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetFilteredContentsUsecase', error, stackTrace);
      return const Left(GetFilteredContentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetFilteredContentsUsecase].
enum GetFilteredContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}

/// Paramètres du [GetFilteredContentsUsecase].
class GetFilteredContentsParams extends Params {
  /// Crée des [GetFilteredContentsParams].
  ///
  /// - [query] : texte saisi par l'utilisateur, comparé au titre des contenus.
  const GetFilteredContentsParams({required this.query});

  /// Texte saisi par l'utilisateur, comparé au titre des contenus.
  final String query;
}
