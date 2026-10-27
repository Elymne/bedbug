import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/repositories/trust_settings_repository.dart';
import 'package:bedbug/features/content/domain/usecases/get_trust_settings_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_trust_settings_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveTrustSettingsUsecase].
final saveTrustSettingsUsecaseProvider = Provider<SaveTrustSettingsUsecase>((ref) {
  return SaveTrustSettingsUsecase(ref.read(trustSettingsRepositoryProvider));
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
  SaveTrustSettingsUsecase(this._trustSettingsRepository);

  final TrustSettingsRepository _trustSettingsRepository;

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
      return const Left(TrustSettingsFailure.unknown);
    }
  }
}

/// Paramètres du [SaveTrustSettingsUsecase].
class SaveTrustSettingsParams extends Params {
  /// Crée des [SaveTrustSettingsParams].
  ///
  /// - [settings] : réglages à enregistrer, `null` pour revenir aux réglages par défaut.
  const SaveTrustSettingsParams({required this.settings});

  /// Réglages à enregistrer, `null` pour revenir aux réglages par défaut.
  final TrustSettings? settings;
}
