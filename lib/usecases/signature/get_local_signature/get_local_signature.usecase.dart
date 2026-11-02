import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.hive.dart';
import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetLocalSignatureUsecase].
final getLocalSignatureUsecaseProvider = Provider<GetLocalSignatureUsecase>((ref) {
  return GetLocalSignatureUsecase(ref.read(signatureRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère le profil de l'utilisateur du téléphone.
///
/// Le profil (pseudo, icône, couleur, réseaux) est ce qui donne du style aux
/// contenus créés sur cet appareil. Il est lu pour être édité dans les
/// options, et le sera plus tard pour signer les contenus. Retourne `null`
/// tant que l'utilisateur n'a jamais enregistré son profil.
class GetLocalSignatureUsecase extends Usecase<NoParams, GetLocalSignatureFailure, Signature?> {
  /// Crée un [GetLocalSignatureUsecase].
  GetLocalSignatureUsecase(this._signatureRepository, this._errorLogRepository);

  final SignatureRepository _signatureRepository;
  final ErrorLogRepository _errorLogRepository;

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
      await _errorLogRepository.record(source: 'GetLocalSignatureUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetLocalSignatureFailure.unknown);
    }
  }
}
