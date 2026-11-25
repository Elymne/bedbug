import 'package:bedbug/infra/resources/content/drawing/drawing.codec.binary.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing_draft.repository.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DriftDrawingDraftRepository].
final drawingDraftRepositoryProvider = Provider<DrawingDraftRepository>((ref) {
  return DriftDrawingDraftRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [DrawingDraftRepository] stockant le brouillon dans la ligne unique de `drawing_drafts`.
///
/// Le brouillon est stocké tel qu'il serait transmis, encodé par [DrawingBinaryCodec] : aucune colonne à maintenir
/// pour chaque champ du dessin, et quelques kilo-octets à réécrire à chaque trait.
class DriftDrawingDraftRepository implements DrawingDraftRepository {
  /// Crée un [DriftDrawingDraftRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftDrawingDraftRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Lit et décode la ligne [singleRowId], absente tant que rien n'a été dessiné.
  ///
  /// Lève une [DataException] si les octets stockés ne forment pas un dessin valide.
  @override
  Future<Drawing?> get() async {
    return guardDrift('DriftDrawingDraftRepository', () async {
      final query = _database.select(_database.drawingDrafts)..where((row) => row.id.equals(singleRowId));
      final row = await query.getSingleOrNull();
      if (row == null) {
        return null;
      }
      try {
        return const DrawingBinaryCodec().decode(row.data);
      } on FormatException catch (error) {
        throw DataException('DriftDrawingDraftRepository', error);
      }
    });
  }

  /// Encode [drawing] et l'écrit dans la ligne [singleRowId], créée au premier trait puis remplacée.
  ///
  /// - [drawing] : dessin en cours d'édition.
  @override
  Future<void> save(Drawing drawing) async {
    await guardDrift('DriftDrawingDraftRepository', () async {
      await _database
          .into(_database.drawingDrafts)
          .insertOnConflictUpdate(
            DrawingDraftsCompanion.insert(
              id: const Value(singleRowId),
              data: const DrawingBinaryCodec().encode(drawing),
            ),
          );
    });
  }

  /// Supprime la ligne [singleRowId].
  @override
  Future<void> clear() async {
    await guardDrift('DriftDrawingDraftRepository', () async {
      await (_database.delete(_database.drawingDrafts)..where((row) => row.id.equals(singleRowId))).go();
    });
  }
}
