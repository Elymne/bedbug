import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.repository.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.repository.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/trust/get_trust_settings/get_trust_settings.failure.dart';
import 'package:bedbug/usecases/trust/save_trust_settings/save_trust_settings.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveTrustSettingsUsecase].
final saveTrustSettingsUsecaseProvider = Provider<SaveTrustSettingsUsecase>((ref) {
  return SaveTrustSettingsUsecase(ref.read(trustSettingsRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Enregistre les réglages de confiance modifiés par l'utilisateur, ou revient aux réglages par défaut.
///
/// L'utilisateur garde la main sur ses listes de domaines : chaque ajout,
/// retrait ou changement de liste passe par ici. Revenir aux réglages par
/// défaut efface les réglages enregistrés plutôt que d'écrire une copie des
/// listes par défaut, pour que les futures mises à jour de ces listes
/// s'appliquent de nouveau.
class SaveTrustSettingsUsecase extends Usecase<SaveTrustSettingsParams, TrustSettingsFailure, TrustSettings> {
  /// Crée un [SaveTrustSettingsUsecase].
  SaveTrustSettingsUsecase(this._trustSettingsRepository, this._errorLogRepository);

  final TrustSettingsRepository _trustSettingsRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<TrustSettingsFailure, TrustSettings>> call(SaveTrustSettingsParams params) async {
    try {
      final settings = params.settings;
      if (settings == null) {
        await _trustSettingsRepository.clear();
        return const Right(defaultTrustSettings);
      }
      await _trustSettingsRepository.save(settings);
      return Right(settings);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveTrustSettingsUsecase', error, stackTrace);
      return const Left(TrustSettingsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveTrustSettingsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveTrustSettingsUsecase', error: error, stackTrace: stackTrace);
      return const Left(TrustSettingsFailure.unknown);
    }
  }
}
