import 'package:bedbug/features/settings/domain/repositories/settings_repository.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/features/settings/infrastructure/datasources/hive_settings_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveSettingsUsecase].
final saveSettingsUsecaseProvider = Provider<SaveSettingsUsecase>(
  (ref) => SaveSettingsUsecase(ref.read(settingsRepositoryProvider)),
);

/// Persiste les settings mis à jour.
///
/// Si aucun settings n'existe encore, en crée un. Sinon, met à jour l'existant.
class SaveSettingsUsecase extends Usecase<SaveSettingsParams, SaveSettingsFailure, UserSettings> {
  /// Crée un [SaveSettingsUsecase].
  SaveSettingsUsecase(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  @override
  Future<Either<SaveSettingsFailure, UserSettings>> call(SaveSettingsParams params) async {
    try {
      final existing = await _settingsRepository.getUnique('');

      if (existing != null) {
        final updated = await _settingsRepository.updateOne(params.settings);
        return Right(updated);
      }

      final created = await _settingsRepository.addOne(params.settings);
      return Right(created);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveSettingsUsecase', error, stackTrace);
      return const Left(SaveSettingsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveSettingsUsecase', error, stackTrace);
      return const Left(SaveSettingsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveSettingsUsecase', error, stackTrace);
      return const Left(SaveSettingsFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveSettingsUsecase].
enum SaveSettingsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}

/// Paramètres du [SaveSettingsUsecase].
class SaveSettingsParams extends Params {
  /// Crée des [SaveSettingsParams].
  ///
  /// - [settings] : settings à persister.
  const SaveSettingsParams({required this.settings});

  /// Settings à persister.
  final UserSettings settings;
}
