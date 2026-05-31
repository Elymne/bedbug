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

/// Provider du [GetSettingsUsecase].
final getSettingsUsecaseProvider = Provider<GetSettingsUsecase>(
  (ref) => GetSettingsUsecase(ref.read(settingsRepositoryProvider)),
);

/// Récupère les settings de l'utilisateur.
///
/// Si aucun settings n'existe encore, en crée un avec les valeurs par défaut
/// et le persiste avant de le retourner.
class GetSettingsUsecase extends Usecase<NoParams, GetSettingsFailure, UserSettings> {
  /// Crée un [GetSettingsUsecase].
  GetSettingsUsecase(this._settingsRepository);

  final SettingsRepository _settingsRepository;

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
      return const Left(GetSettingsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetSettingsUsecase].
enum GetSettingsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
