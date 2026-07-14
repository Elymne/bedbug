import 'package:bedbug/features/content/domain/entities/storage.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Clé Hive sous laquelle la configuration de stockage est persistée.
const String _storageKey = 'storage_config';

/// Provider de la [Box] Hive de la configuration de stockage.
final hiveStorageBoxProvider = Provider<Box<StorageHiveModel>>((ref) => Hive.box<StorageHiveModel>('storage'));

/// Provider du [HiveStorageRepository].
final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => HiveStorageRepository(ref.read(hiveStorageBoxProvider)),
);

/// Implémentation de [StorageRepository] utilisant Hive comme stockage local.
class HiveStorageRepository implements StorageRepository {
  /// Crée un [HiveStorageRepository].
  HiveStorageRepository(this._box);

  final Box<StorageHiveModel> _box;

  /// Lit l'entrée Hive stockée sous la clé fixe [_storageKey], la seule clé
  /// jamais utilisée par les écritures de ce repository.
  @override
  Future<Storage?> getUnique(String id) async {
    try {
      return _box.get(_storageKey)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveStorageRepository', error);
    }
  }

  /// Compte le nombre brut d'entrées de la box, sans filtrer sur
  /// [_storageKey] : c'est justement ce comptage non filtré qui permet à
  /// `GetStorageUsecase` de détecter une entrée écrite par erreur sous une
  /// autre clé, cas que [getUnique] ne peut pas voir puisqu'il ne regarde
  /// que [_storageKey].
  @override
  Future<int> countAll() async {
    try {
      return _box.length;
    } on HiveError catch (error) {
      throw DatasourceException('HiveStorageRepository', error);
    }
  }

  /// Écrit toujours sous la clé fixe [_storageKey], quel que soit
  /// `entity.id` : ce repository ne gère qu'un singleton, il n'y a donc
  /// qu'un seul emplacement possible en base.
  @override
  Future<Storage> addOne(Storage entity) async {
    try {
      await _box.put(_storageKey, StorageHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveStorageRepository', error);
    }
  }

  /// Refuse la mise à jour si aucune configuration n'a encore été créée
  /// via [addOne], pour éviter de silencieusement faire apparaître une
  /// configuration jamais initialisée.
  @override
  Future<Storage> updateOne(Storage entity) async {
    try {
      if (!_box.containsKey(_storageKey)) {
        throw const DatasourceException('HiveStorageRepository', 'storage not found — call addOne first');
      }
      await _box.put(_storageKey, StorageHiveModel.fromEntity(entity));
      return entity;
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveStorageRepository', error);
    }
  }

  /// Crée la configuration avec les valeurs par défaut si elle n'existe pas
  /// encore, sinon ajoute [deltaBytes] (positif ou négatif) à
  /// `currentSizeInBytes` existant.
  ///
  /// Le résultat est toujours plafonné à `0` au minimum : `deltaBytes`
  /// négatif ne doit jamais faire passer le compteur sous zéro, même en cas
  /// de décalage entre ce compteur incrémental et le contenu réellement
  /// stocké (voir `RecalculateStorageUsageUsecase` pour la réconciliation
  /// complète).
  @override
  Future<void> adjustCurrentSizeInBytes(int deltaBytes) async {
    final existing = await getUnique('');

    if (existing == null) {
      final now = DateTime.now();
      await addOne(
        Storage(
          id: UuidX.generate(),
          createdAt: now,
          updatedAt: now,
          maxSizeInBytes: defaultMaxStorageSizeInBytes,
          currentSizeInBytes: deltaBytes < 0 ? 0 : deltaBytes,
        ),
      );
      return;
    }

    final newSize = existing.currentSizeInBytes + deltaBytes;
    await updateOne(existing.copyWithCurrentSizeInBytes(newSize < 0 ? 0 : newSize));
  }

  /// Ne fait rien si la configuration n'existe pas encore : il n'y a alors
  /// rien à réinitialiser, `currentSizeInBytes` vaudra `0` par défaut dès sa
  /// création.
  @override
  Future<void> resetCurrentSizeInBytes() async {
    final existing = await getUnique('');

    if (existing == null) {
      return;
    }

    await updateOne(existing.copyWithCurrentSizeInBytes(0));
  }

  /// Non supporté : ce repository ne gère qu'un singleton, l'ajout en masse
  /// n'a pas de sens ici.
  @override
  Future<void> addMany(List<Storage> entities) {
    throw UnimplementedError(
      'addMany is not supported: StorageRepository manages a single singleton entity, there is nothing to bulk-insert',
    );
  }

  /// Non supporté : ce repository ne gère qu'un singleton, la mise à jour en
  /// masse n'a pas de sens ici.
  @override
  Future<void> updateMany(List<Storage> entities) {
    throw UnimplementedError(
      'updateMany is not supported: StorageRepository manages a single singleton entity, there is nothing to bulk-update',
    );
  }

  /// Non supporté : ce repository ne gère qu'un singleton, il n'y a pas de
  /// collection à lister.
  @override
  Future<List<Storage>> getAll() {
    throw UnimplementedError(
      'getAll is not supported: StorageRepository manages a single singleton entity, not a collection — use getUnique instead',
    );
  }

  /// Non supporté : ce repository ne gère qu'un singleton, il n'y a pas de
  /// collection à observer.
  @override
  Stream<List<Storage>> watchAll() {
    throw UnimplementedError(
      'watchAll is not supported: StorageRepository manages a single singleton entity, not a collection to watch',
    );
  }

  /// Non supporté : la configuration de stockage n'est jamais supprimée
  /// individuellement.
  @override
  Future<void> deleteOne(String id) {
    throw UnimplementedError(
      'deleteOne is not supported: the storage configuration singleton is never deleted, only created or updated',
    );
  }

  /// Non supporté : la configuration de stockage n'est jamais supprimée
  /// individuellement.
  @override
  Future<void> deleteMany(List<String> ids) {
    throw UnimplementedError(
      'deleteMany is not supported: the storage configuration singleton is never deleted, only created or updated',
    );
  }

  /// Non supporté : la configuration de stockage n'est jamais supprimée
  /// individuellement.
  @override
  Future<void> deleteAll() {
    throw UnimplementedError(
      'deleteAll is not supported: the storage configuration singleton is never deleted, only created or updated',
    );
  }

  /// Non supporté : ce repository ne gère qu'un singleton, le filtrage n'a
  /// pas de sens ici.
  @override
  Future<List<Storage>> findMany(StorageRepositoryParams params) {
    throw UnimplementedError(
      'findMany is not supported: StorageRepository manages a single singleton entity, filtering has no meaning here',
    );
  }

  /// Non supporté : ce repository ne gère qu'un singleton, le filtrage n'a
  /// pas de sens ici.
  @override
  Stream<List<Storage>> watchMany(StorageRepositoryParams params) {
    throw UnimplementedError(
      'watchMany is not supported: StorageRepository manages a single singleton entity, filtering has no meaning here',
    );
  }
}
