import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.repository.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.repository.drift.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:bedbug/logic/usecases/settings/get_settings/get_settings.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetSettingsUsecase].
final getSettingsUsecaseProvider = Provider<GetSettingsUsecase>((ref) {
  return GetSettingsUsecase(ref.read(userSettingsRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère les settings de l'utilisateur.
///
/// Si aucun settings n'existe encore, en crée un avec les valeurs par défaut
/// et le persiste avant de le retourner.
class GetSettingsUsecase extends Usecase<NoParams, GetSettingsFailure, UserSettings> {
  /// Crée un [GetSettingsUsecase].
  GetSettingsUsecase(this._settingsRepository, this._errorLogRepository);

  final UserSettingsRepository _settingsRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetSettingsFailure, UserSettings>> call(NoParams params) async {
    try {
      final existing = await _settingsRepository.get();

      if (existing != null) {
        return Right(existing);
      }

      await _settingsRepository.save(defaultUserSettings);
      return const Right(defaultUserSettings);
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
