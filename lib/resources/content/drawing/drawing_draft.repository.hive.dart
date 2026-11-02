import 'dart:typed_data';

import 'package:bedbug/resources/content/drawing/drawing.codec.binary.dart';
import 'package:bedbug/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/resources/content/drawing/drawing_draft.repository.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Clé Hive sous laquelle le brouillon de dessin est persisté.
const String _draftKey = 'drawing_draft';

/// Provider de la [Box] Hive du brouillon de dessin.
final hiveDrawingDraftBoxProvider = Provider<Box<Uint8List>>((ref) => Hive.box<Uint8List>(drawingDraftBoxName));

/// Provider du [DrawingDraftRepository].
final drawingDraftRepositoryProvider = Provider<DrawingDraftRepository>((ref) {
  return HiveDrawingDraftRepository(ref.read(hiveDrawingDraftBoxProvider));
});

/// Implémentation de [DrawingDraftRepository] utilisant Hive comme stockage local.
///
/// Le brouillon est stocké tel qu'il serait transmis, encodé par
/// [DrawingBinaryCodec] : aucun modèle Hive à maintenir, et quelques
/// kilo-octets à réécrire à chaque trait.
class HiveDrawingDraftRepository implements DrawingDraftRepository {
  /// Crée un [HiveDrawingDraftRepository].
  HiveDrawingDraftRepository(this._box);

  /// Box Hive du brouillon.
  final Box<Uint8List> _box;

  @override
  Future<Drawing?> get() async {
    try {
      final bytes = _box.get(_draftKey);
      if (bytes == null) {
        return null;
      }
      return const DrawingBinaryCodec().decode(bytes);
    } on FormatException catch (error) {
      throw DataException('HiveDrawingDraftRepository', error);
    } on HiveError catch (error) {
      throw DatasourceException('HiveDrawingDraftRepository', error);
    }
  }

  @override
  Future<void> save(Drawing drawing) async {
    try {
      await _box.put(_draftKey, const DrawingBinaryCodec().encode(drawing));
    } on HiveError catch (error) {
      throw DatasourceException('HiveDrawingDraftRepository', error);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.delete(_draftKey);
    } on HiveError catch (error) {
      throw DatasourceException('HiveDrawingDraftRepository', error);
    }
  }
}
