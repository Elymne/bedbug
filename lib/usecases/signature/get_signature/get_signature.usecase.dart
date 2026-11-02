import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature.repository.dart';
import 'package:bedbug/resources/signature/signature.repository.hive.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.failure.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetSignatureUsecase].
final getSignatureUsecaseProvider = Provider<GetSignatureUsecase>((ref) {
  return GetSignatureUsecase(ref.read(signatureRepositoryProvider));
});

/// Retrouve le profil à afficher pour l'auteur d'un contenu.
///
/// Un contenu ne porte que l'identifiant de sa signature. Pour lui donner un
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
      if (params.signatureId == anonymousSignatureId) {
        return Right(anonymousSignature);
      }
      final signature = await _signatureRepository.getById(params.signatureId);
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
