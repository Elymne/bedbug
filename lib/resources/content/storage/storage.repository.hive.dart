import 'package:bedbug/resources/content/storage/storage.config.dart';
import 'package:bedbug/resources/content/storage/storage.model.hive.dart';
import 'package:bedbug/resources/content/storage/storage.repository.dart';
import 'package:bedbug/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Clé Hive sous laquelle la configuration de stockage est persistée.
const String _storageKey = 'storage_config';

/// Provider de la [Box] Hive de la configuration de stockage.
final hiveStorageBoxProvider = Provider<Box<StorageHiveModel>>((ref) => Hive.box<StorageHiveModel>(storageBoxName));

/// Provider du [HiveStorageRepository].
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return HiveStorageRepository(ref.read(hiveStorageBoxProvider));
});

/// Implémentation de [StorageRepository] utilisant Hive comme stockage local.
class HiveStorageRepository implements StorageRepository {
  /// Crée un [HiveStorageRepository].
  HiveStorageRepository(this._box);

  final Box<StorageHiveModel> _box;

  /// Lit l'entrée Hive stockée sous la clé fixe [_storageKey], la seule clé jamais utilisée par les écritures de ce
  /// repository.
  @override
  Future<Storage?> get() async {
    try {
      return _box.get(_storageKey)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveStorageRepository', error);
    }
  }

  /// Compte le nombre brut d'entrées de la box, sans filtrer sur [_storageKey] : c'est justement ce comptage non
  /// filtré qui permet à `GetStorageUsecase` de détecter une entrée écrite par erreur sous une autre clé, cas que
  /// [get] ne peut pas voir puisqu'il ne regarde que [_storageKey].
  @override
  Future<int> countAll() async {
    try {
      return _box.length;
    } on HiveError catch (error) {
      throw DatasourceException('HiveStorageRepository', error);
    }
  }

  /// Écrit toujours sous la clé fixe [_storageKey] : ce repository ne gère qu'une configuration, il n'y a donc qu'un
  /// seul emplacement possible en base.
  @override
  Future<void> save(Storage storage) async {
    try {
      await _box.put(_storageKey, StorageHiveModel.fromEntity(storage));
    } on HiveError catch (error) {
      throw DatasourceException('HiveStorageRepository', error);
    }
  }

  /// Part de la configuration par défaut si elle n'existe pas encore, puis ajoute [deltaBytes] (positif ou négatif)
  /// à `currentSizeInBytes`.
  ///
  /// Le résultat est toujours plafonné à `0` au minimum : `deltaBytes` négatif ne doit jamais faire passer le
  /// compteur sous zéro, même en cas de décalage entre ce compteur incrémental et le contenu réellement stocké (voir
  /// `RecalculateStorageUsageUsecase` pour la réconciliation complète).
  @override
  Future<void> adjustCurrentSizeInBytes(int deltaBytes) async {
    final storage = await get() ?? defaultStorage;
    final newSize = storage.currentSizeInBytes + deltaBytes;
    await save(storage.copyWithCurrentSizeInBytes(newSize < 0 ? 0 : newSize));
  }

  /// Ne fait rien si la configuration n'existe pas encore : il n'y a alors rien à réinitialiser,
  /// `currentSizeInBytes` vaudra `0` par défaut dès sa création.
  @override
  Future<void> resetCurrentSizeInBytes() async {
    final storage = await get();
    if (storage == null) {
      return;
    }
    await save(storage.copyWithCurrentSizeInBytes(0));
  }
}
