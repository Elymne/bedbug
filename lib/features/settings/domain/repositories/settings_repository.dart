import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/repository.dart';

/// Contrat du repository gérant les [UserSettings].
///
/// Ce repository gère un unique objet de configuration.
/// Les opérations de liste, pagination et suppression ne sont pas supportées.
abstract class SettingsRepository extends Repository<UserSettings, SettingsRepositoryParams> {
  /// Retourne les settings persistés, ou `null` si jamais initialisés.
  @override
  Future<UserSettings?> getUnique(String id);

  /// Persiste les [UserSettings] fournis.
  @override
  Future<UserSettings> addOne(UserSettings entity);

  /// Met à jour les [UserSettings] existants.
  ///
  /// Lève une `DatasourceException` si aucun settings n'a encore été persisté.
  @override
  Future<UserSettings> updateOne(UserSettings entity);

  @override
  Future<void> addMany(List<UserSettings> entities) {
    throw UnimplementedError('addMany is not supported');
  }

  @override
  Future<void> updateMany(List<UserSettings> entities) {
    throw UnimplementedError('updateMany is not supported');
  }

  @override
  Future<List<UserSettings>> getAll() {
    throw UnimplementedError('getAll is not supported');
  }

  @override
  Stream<List<UserSettings>> watchAll() {
    throw UnimplementedError('watchAll is not supported');
  }

  @override
  Future<void> deleteOne(String id) {
    throw UnimplementedError('deleteOne is not supported');
  }

  @override
  Future<void> deleteMany(List<String> ids) {
    throw UnimplementedError('deleteMany is not supported');
  }

  @override
  Future<void> deleteAll() {
    throw UnimplementedError('deleteAll is not supported');
  }

  @override
  Future<List<UserSettings>> findMany(SettingsRepositoryParams params) {
    throw UnimplementedError('findMany is not supported');
  }

  @override
  Stream<List<UserSettings>> watchMany(SettingsRepositoryParams params) {
    throw UnimplementedError('watchMany is not supported');
  }
}

/// Paramètres de requête du [SettingsRepository] — non utilisés.
class SettingsRepositoryParams extends Params {
  /// Crée des [SettingsRepositoryParams].
  const SettingsRepositoryParams();
}
