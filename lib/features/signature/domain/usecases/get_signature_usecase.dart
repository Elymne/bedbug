import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/datasources/hive_signature_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetSignatureUsecase].
final getSignatureUsecaseProvider = Provider<GetSignatureUsecase>(
  (ref) => GetSignatureUsecase(ref.read(signatureRepositoryProvider)),
);

/// Retrouve le profil à afficher pour l'auteur d'un contenu.
///
/// Un contenu ne porte que l'identifiant de son auteur. Pour lui donner un
/// visage sur la page de détail (pseudo, icône, couleur), on cherche ce
/// profil sur l'appareil. Un contenu anonyme, ou dont l'auteur est inconnu
/// de l'appareil (profil jamais configuré, pair dont on n'a pas reçu le
/// profil), est présenté avec le profil [anonymousSignature] : on n'affiche
/// jamais un auteur qu'on ne connaît pas.
class GetSignatureUsecase extends Usecase<GetSignatureParams, GetSignatureFailure, Signature> {
  /// Crée un [GetSignatureUsecase].
  GetSignatureUsecase(this._signatureRepository);

  final SignatureRepository _signatureRepository;

  @override
  Future<Either<GetSignatureFailure, Signature>> call(GetSignatureParams params) async {
    try {
      if (params.authorId == anonymousSignatureId) {
        return Right(anonymousSignature);
      }
      final signature = await _signatureRepository.getById(params.authorId);
      return Right(signature ?? anonymousSignature);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetSignatureUsecase', error, stackTrace);
      return const Left(GetSignatureFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetSignatureUsecase', error, stackTrace);
      return const Left(GetSignatureFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetSignatureUsecase', error, stackTrace);
      return const Left(GetSignatureFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetSignatureUsecase].
enum GetSignatureFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture du profil.
  unknown,
}

/// Paramètres du [GetSignatureUsecase].
class GetSignatureParams extends Params {
  /// Crée des [GetSignatureParams].
  ///
  /// - [authorId] : identifiant d'auteur porté par le contenu.
  const GetSignatureParams({required this.authorId});

  /// Identifiant d'auteur porté par le contenu.
  final String authorId;
}
