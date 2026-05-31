import 'package:bedbug/features/discovery/domain/entities/keychain.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'keychain_hive_model.g.dart';

/// DTO Hive représentant un [Keychain] persisté localement.
@HiveType(typeId: HiveTypeIds.keychain)
class KeychainHiveModel extends HiveObject {
  /// Crée un [KeychainHiveModel].
  KeychainHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.label,
    required this.subId,
    required this.keys,
  });

  /// Crée un [KeychainHiveModel] depuis une entité [Keychain].
  factory KeychainHiveModel.fromEntity(Keychain entity) {
    return KeychainHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      label: entity.label,
      subId: entity.subId,
      keys: entity.keys.map((key) => PrivateKeyHiveModel.fromValueObject(key)).toList(),
    );
  }

  /// Identifiant unique du portefeuille.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Libellé lisible du portefeuille.
  @HiveField(3)
  final String label;

  /// Identifiant du sub associé.
  @HiveField(4)
  final String subId;

  /// Clés privées persistées.
  @HiveField(5)
  final List<PrivateKeyHiveModel> keys;

  /// Convertit ce modèle en entité [Keychain].
  Keychain toEntity() {
    try {
      return Keychain(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        label: label,
        subId: subId,
        keys: keys.map((key) => key.toValueObject()).toList(),
      );
    } catch (error) {
      throw DataException('KeychainHiveModel', error);
    }
  }
}

/// DTO Hive représentant une [PrivateKey] persistée localement.
@HiveType(typeId: HiveTypeIds.privateKey)
class PrivateKeyHiveModel extends HiveObject {
  /// Crée un [PrivateKeyHiveModel].
  PrivateKeyHiveModel({required this.value, required this.createdAt});

  /// Crée un [PrivateKeyHiveModel] depuis un value object [PrivateKey].
  factory PrivateKeyHiveModel.fromValueObject(PrivateKey key) {
    return PrivateKeyHiveModel(value: key.value, createdAt: key.createdAt.millisecondsSinceEpoch);
  }

  /// Valeur brute de la clé privée.
  @HiveField(0)
  final String value;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Convertit ce modèle en value object [PrivateKey].
  PrivateKey toValueObject() {
    try {
      return PrivateKey(value: value, createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt));
    } catch (error) {
      throw DataException('PrivateKeyHiveModel', error);
    }
  }
}
