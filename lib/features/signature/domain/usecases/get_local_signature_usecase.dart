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

/// Provider du [GetLocalSignatureUsecase].
final getLocalSignatureUsecaseProvider = Provider<GetLocalSignatureUsecase>((ref) {
  return GetLocalSignatureUsecase(ref.read(signatureRepositoryProvider));
});

/// Récupère le profil de l'utilisateur du téléphone.
///
/// Le profil (pseudo, icône, couleur, réseaux) est ce qui donne du style aux
/// contenus créés sur cet appareil. Il est lu pour être édité dans les
/// options, et le sera plus tard pour signer les contenus. Retourne `null`
/// tant que l'utilisateur n'a jamais enregistré son profil.
class GetLocalSignatureUsecase extends Usecase<NoParams, GetLocalSignatureFailure, Signature?> {
  /// Crée un [GetLocalSignatureUsecase].
  GetLocalSignatureUsecase(this._signatureRepository);

  final SignatureRepository _signatureRepository;

  @override
  Future<Either<GetLocalSignatureFailure, Signature?>> call(NoParams params) async {
    try {
      final signature = await _signatureRepository.getLocal();
      return Right(signature);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetLocalSignatureUsecase', error, stackTrace);
      return const Left(GetLocalSignatureFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetLocalSignatureUsecase', error, stackTrace);
      return const Left(GetLocalSignatureFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetLocalSignatureUsecase', error, stackTrace);
      return const Left(GetLocalSignatureFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetLocalSignatureUsecase].
enum GetLocalSignatureFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture du profil.
  unknown,
}
