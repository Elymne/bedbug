import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.mapper.drift.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Caractère d'échappement des motifs `LIKE` : neutralise les jokers `%` et `_` saisis par l'utilisateur.
const String _likeEscapeCharacter = r'\';

/// Provider du [DriftSignatureRepository].
final signatureRepositoryProvider = Provider<SignatureRepository>((ref) {
  return DriftSignatureRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [SignatureRepository] stockant les signatures dans la table SQLite `signatures`.
class DriftSignatureRepository implements SignatureRepository {
  /// Crée un [DriftSignatureRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftSignatureRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Lit la signature de l'utilisateur du téléphone, rangée sous [localSignatureId].
  @override
  Future<Signature?> getLocal() async {
    return guardDrift('DriftSignatureRepository', () async {
      return _findById(localSignatureId);
    });
  }

  /// Lit la signature d'identifiant [id].
  ///
  /// - [id] : identifiant de la signature recherchée.
  @override
  Future<Signature?> getById(String id) async {
    return guardDrift('DriftSignatureRepository', () async {
      return _findById(id);
    });
  }

  /// Cherche les signatures dont le pseudo commence par [prefix], en laissant SQLite filtrer, trier et limiter.
  ///
  /// Appelée à chaque frappe : seules les [limit] signatures retenues sont lues et converties. Le `LIKE` de SQLite
  /// ignore la casse des lettres ASCII, les seules autorisées dans un pseudo, et profite de l'index
  /// `signatures_pseudo` (en `NOCASE`). Les jokers `%` et `_` de la saisie sont échappés pour rester littéraux.
  ///
  /// - [prefix] : début du pseudo saisi.
  /// - [limit] : nombre maximal de signatures retournées.
  @override
  Future<List<Signature>> getAllWithPseudoStartingWith(String prefix, {required int limit}) async {
    return guardDrift('DriftSignatureRepository', () async {
      final table = _database.signatures;
      final escapedPrefix = prefix
          .replaceAll(_likeEscapeCharacter, '$_likeEscapeCharacter$_likeEscapeCharacter')
          .replaceAll('%', '$_likeEscapeCharacter%')
          .replaceAll('_', '${_likeEscapeCharacter}_');
      final query = _database.select(table)
        ..where((row) => row.pseudo.like('$escapedPrefix%', escapeChar: _likeEscapeCharacter))
        ..orderBy([(row) => OrderingTerm(expression: row.pseudo.collate(Collate.noCase))])
        ..limit(limit);
      final rows = await query.get();
      return rows.map(SignatureDriftMapper.toEntity).toList();
    });
  }

  /// Écrit [entity] sous [localSignatureId], quel que soit son propre identifiant.
  ///
  /// - [entity] : signature de l'utilisateur du téléphone.
  @override
  Future<Signature> saveLocal(Signature entity) async {
    return guardDrift('DriftSignatureRepository', () async {
      await _database
          .into(_database.signatures)
          .insertOnConflictUpdate(SignatureDriftMapper.toCompanion(entity, id: localSignatureId));
      return entity;
    });
  }

  /// Écrit [entities] dans un seul lot, chacune remplaçant la signature de même identifiant.
  ///
  /// Un upsert plutôt qu'un `REPLACE` : ce dernier supprime puis réinsère la ligne, ce qui déclencherait les
  /// suppressions en cascade des tables qui la référencent.
  ///
  /// - [entities] : signatures à écrire.
  @override
  Future<void> saveMany(List<Signature> entities) async {
    await guardDrift('DriftSignatureRepository', () async {
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(_database.signatures, entities.map(SignatureDriftMapper.toCompanion));
      });
    });
  }

  /// Lit la ligne d'identifiant [id] et la convertit, ou retourne `null` si elle n'existe pas.
  ///
  /// - [id] : identifiant de la ligne.
  Future<Signature?> _findById(String id) async {
    final query = _database.select(_database.signatures)..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return SignatureDriftMapper.toEntity(row);
  }
}
