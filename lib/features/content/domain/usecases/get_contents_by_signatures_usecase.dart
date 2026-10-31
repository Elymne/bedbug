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

/// Provider du [GetContentsBySignaturesUsecase].
final getContentsBySignaturesUsecaseProvider = Provider<GetContentsBySignaturesUsecase>((ref) {
  return GetContentsBySignaturesUsecase(ref.read(contentRepositoryProvider));
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
  GetContentsBySignaturesUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

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
      return const Left(GetContentsBySignaturesFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetContentsBySignaturesUsecase].
enum GetContentsBySignaturesFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}

/// Paramètres du [GetContentsBySignaturesUsecase].
class GetContentsBySignaturesParams extends Params {
  /// Crée des [GetContentsBySignaturesParams].
  ///
  /// - [signatureIds] : identifiants des signatures dont on veut les contenus.
  const GetContentsBySignaturesParams({required this.signatureIds});

  /// Identifiants des signatures dont on veut les contenus.
  final List<String> signatureIds;
}
