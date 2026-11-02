import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/settings/settings.repository.dart';
import 'package:bedbug/resources/settings/settings.repository.hive.dart';
import 'package:bedbug/resources/settings/user_settings.value_object.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.failure.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveSettingsUsecase].
final saveSettingsUsecaseProvider = Provider<SaveSettingsUsecase>((ref) {
  return SaveSettingsUsecase(ref.read(settingsRepositoryProvider));
});

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
