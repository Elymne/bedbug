import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/settings/settings/settings.repository.dart';
import 'package:bedbug/resources/settings/settings/settings.repository.hive.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetSettingsUsecase].
final getSettingsUsecaseProvider = Provider<GetSettingsUsecase>((ref) {
  return GetSettingsUsecase(ref.read(settingsRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère les settings de l'utilisateur.
///
/// Si aucun settings n'existe encore, en crée un avec les valeurs par défaut
/// et le persiste avant de le retourner.
class GetSettingsUsecase extends Usecase<NoParams, GetSettingsFailure, UserSettings> {
  /// Crée un [GetSettingsUsecase].
  GetSettingsUsecase(this._settingsRepository, this._errorLogRepository);

  final SettingsRepository _settingsRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetSettingsFailure, UserSettings>> call(NoParams params) async {
    try {
      final existing = await _settingsRepository.getUnique('');

      if (existing != null) {
        return Right(existing);
      }

      const defaults = UserSettings.empty();
      await _settingsRepository.addOne(defaults);
      return const Right(defaults);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetSettingsUsecase', error, stackTrace);
      return const Left(GetSettingsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetSettingsUsecase', error, stackTrace);
      return const Left(GetSettingsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetSettingsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetSettingsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetSettingsFailure.unknown);
    }
  }
}
