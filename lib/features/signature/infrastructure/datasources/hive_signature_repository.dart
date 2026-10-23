import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/models/signature_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des utilisateurs.
final hiveSignatureBoxProvider = Provider<Box<SignatureHiveModel>>((ref) => Hive.box<SignatureHiveModel>('signatures'));

/// Provider du [HiveSignatureRepository].
final signatureRepositoryProvider = Provider<SignatureRepository>(
  (ref) => HiveSignatureRepository(ref.read(hiveSignatureBoxProvider)),
);

/// Implémentation de [SignatureRepository] utilisant Hive comme stockage local.
class HiveSignatureRepository implements SignatureRepository {
  /// Crée un [HiveSignatureRepository].
  HiveSignatureRepository(this._box);

  final Box<SignatureHiveModel> _box;

  @override
  Future<Signature?> getLocal() async {
    try {
      return _box.get(localSignatureId)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSignatureRepository', error);
    }
  }

  @override
  Future<Signature?> getById(String id) async {
    try {
      return _box.get(id)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSignatureRepository', error);
    }
  }

  @override
  Future<List<Signature>> getAllWithPseudoStartingWith(String prefix, {required int limit}) async {
    try {
      final lowerCasePrefix = prefix.toLowerCase();
      // Filtre et tri sur le modèle : seules les signatures retenues paient
      // le coût de `toEntity()`, appelé ici à chaque frappe.
      final models = _box.values.where((model) => model.pseudo.toLowerCase().startsWith(lowerCasePrefix)).toList()
        ..sort((first, second) => first.pseudo.toLowerCase().compareTo(second.pseudo.toLowerCase()));
      return models.take(limit).map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSignatureRepository', error);
    }
  }

  @override
  Future<void> saveMany(List<Signature> entities) async {
    try {
      await _box.putAll({for (final entity in entities) entity.id: SignatureHiveModel.fromEntity(entity)});
    } on HiveError catch (error) {
      throw DatasourceException('HiveSignatureRepository', error);
    }
  }

  @override
  Future<Signature> saveLocal(Signature entity) async {
    try {
      await _box.put(localSignatureId, SignatureHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveSignatureRepository', error);
    }
  }
}
