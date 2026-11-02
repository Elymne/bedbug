import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/trust_settings.repository.dart';
import 'package:bedbug/resources/content/trust_settings.repository.hive.dart';
import 'package:bedbug/resources/content/trust_settings.value_object.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/trust/get_trust_settings/get_trust_settings.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetTrustSettingsUsecase].
final getTrustSettingsUsecaseProvider = Provider<GetTrustSettingsUsecase>((ref) {
  return GetTrustSettingsUsecase(ref.read(trustSettingsRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère les réglages de confiance de l'utilisateur, ou les réglages par défaut s'il n'a rien modifié.
///
/// Chaque média, chaque lien affiché passe par ces réglages : ils décident
/// de ce que le téléphone a le droit de contacter. Les réglages par défaut
/// ne sont pas enregistrés tant que l'utilisateur n'a rien changé, pour
/// qu'une mise à jour des listes par défaut profite à ceux qui n'y ont pas
/// touché.
class GetTrustSettingsUsecase extends Usecase<NoParams, TrustSettingsFailure, TrustSettings> {
  /// Crée un [GetTrustSettingsUsecase].
  GetTrustSettingsUsecase(this._trustSettingsRepository, this._errorLogRepository);

  final TrustSettingsRepository _trustSettingsRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<TrustSettingsFailure, TrustSettings>> call(NoParams params) async {
    try {
      return Right(await _trustSettingsRepository.get() ?? defaultTrustSettings);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetTrustSettingsUsecase', error, stackTrace);
      return const Left(TrustSettingsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetTrustSettingsUsecase', error, stackTrace);
      return const Left(TrustSettingsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetTrustSettingsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetTrustSettingsUsecase', error: error, stackTrace: stackTrace);
      return const Left(TrustSettingsFailure.unknown);
    }
  }
}
