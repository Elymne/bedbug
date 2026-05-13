import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/shared/query/page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des contenus.
final hiveContentBoxProvider = Provider<Box<ContentHiveModel>>(
  (ref) => Hive.box<ContentHiveModel>('contents'),
);

/// Provider du [HiveContentRepository].
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => HiveContentRepository(ref.read(hiveContentBoxProvider)),
);

/// Implémentation de [ContentRepository] utilisant Hive comme stockage local.
class HiveContentRepository implements ContentRepository {
  /// Crée un [HiveContentRepository].
  HiveContentRepository(this._box);

  final Box<ContentHiveModel> _box;

  @override
  Future<Content> addOne(Content entity) async {
    await _box.put(entity.id, ContentHiveModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<Content> updateOne(Content entity) async {
    await _box.put(entity.id, ContentHiveModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<Content?> getUnique(String id) async {
    return _box.get(id)?.toEntity();
  }

  @override
  Future<List<Content>> getAll() async {
    return _box.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> deleteOne(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    await _box.clear();
  }

  @override
  Future<Page<Content>> getMany(ContentRepositoryParams params) async {
    var results = _box.values.map((model) => model.toEntity()).toList();

    if (params.authorId != null) {
      results = results
          .where((content) => content.authorId == params.authorId)
          .toList();
    }

    if (params.orderBy != null) {
      results.sort((a, b) {
        final comparison = switch (params.orderBy!.field) {
          'createdAt' => a.createdAt.compareTo(b.createdAt),
          'updatedAt' => a.updatedAt.compareTo(b.updatedAt),
          _ => 0,
        };
        return params.orderBy!.descending ? -comparison : comparison;
      });
    }

    return Page(items: results, total: results.length);
  }
}
