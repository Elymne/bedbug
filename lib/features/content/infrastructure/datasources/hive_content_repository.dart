import 'dart:math';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/extensions/content_title_extension.dart';
import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:bedbug/features/content/domain/object_values/flair_suggestion.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider du [HiveContentRepository].
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return HiveContentRepository(ref.read(hiveContentBoxProvider));
});

/// Provider de la [Box] Hive des contenus.
final hiveContentBoxProvider = Provider<Box<ContentHiveModel>>((ref) => Hive.box<ContentHiveModel>('contents'));

/// Implémentation de [ContentRepository] utilisant Hive comme stockage local.
class HiveContentRepository implements ContentRepository {
  /// Crée un [HiveContentRepository].
  HiveContentRepository(this._box);

  final Box<ContentHiveModel> _box;

  @override
  Future<Content> addOne(Content entity) async {
    try {
      await _box.put(entity.id, ContentHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> addMany(List<Content> entities) async {
    try {
      await _box.putAll({for (final entity in entities) entity.id: ContentHiveModel.fromEntity(entity)});
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> updateMany(List<Content> entities) async {
    try {
      for (final entity in entities) {
        if (!_box.containsKey(entity.id)) {
          throw DatasourceException('HiveContentRepository', 'entity with id "${entity.id}" not found');
        }
      }
      await _box.putAll({for (final entity in entities) entity.id: ContentHiveModel.fromEntity(entity)});
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAll() async {
    try {
      return _box.values.map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAllOrderedByDisplayScoreDesc() async {
    try {
      final results = _box.values.map((model) => model.toEntity()).toList();
      results.sort((a, b) => b.displayScore.compareTo(a.displayScore));
      return results;
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAllMatchingTitleOrFlair(String query) async {
    try {
      final lowerCaseQuery = query.toLowerCase();
      // Les flairs sont stockés normalisés (sans `/`, en minuscules) : la
      // saisie l'est aussi pour que `/france` trouve le flair `france`.
      final flairQuery = query.toFlair() ?? lowerCaseQuery;
      return _box.values.map((model) => model.toEntity()).where((content) {
        return content.title.toLowerCase().contains(lowerCaseQuery) || content.flair.contains(flairQuery);
      }).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAllByFlair(String flair) async {
    try {
      // Filtre sur le modèle avant conversion : seuls les contenus retenus
      // paient le coût de `toEntity()`.
      return _box.values.where((model) => model.flair == flair).map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAllBySignatures(Set<String> signatureIds) async {
    try {
      return _box.values
          .where((model) => signatureIds.contains(model.signatureId))
          .map((model) => model.toEntity())
          .toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAllByOrigin(ContentOrigin origin) async {
    try {
      return _box.values.where((model) => model.origin == origin.value).map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<Content?> getById(String id) async {
    try {
      return _box.get(id)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getByIds(List<String> ids) async {
    try {
      return ids.map(_box.get).whereType<ContentHiveModel>().map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<Set<String>> getExistingIds(Set<String> ids) async {
    try {
      return ids.where(_box.containsKey).toSet();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getTopByBroadcastScore(int limit) async {
    try {
      // Tri sur les modèles avant conversion : seuls les contenus retenus paient le coût de `toEntity()`.
      final models = _box.values.toList()
        ..sort((first, second) => second.broadcastScore.compareTo(first.broadcastScore));
      return models.take(limit).map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getRandomExcluding(int limit, Set<String> excludedIds, Random random) async {
    try {
      // Tirage sur les modèles avant conversion : seuls les contenus retenus paient le coût de `toEntity()`.
      final models = _box.values.where((model) => !excludedIds.contains(model.id)).toList()..shuffle(random);
      return models.take(limit).map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> deleteOne(String id) async {
    try {
      await _box.delete(id);
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<FlairSuggestion>> getFlairsStartingWith(String prefix, {required int limit}) async {
    try {
      // Appelée à chaque frappe : on ne lit que le flair des modèles, sans
      // jamais les convertir en entités.
      final countsByFlair = <String, int>{};
      for (final model in _box.values) {
        if (model.flair.startsWith(prefix)) {
          countsByFlair.update(model.flair, (count) => count + 1, ifAbsent: () => 1);
        }
      }

      final suggestions = [
        for (final entry in countsByFlair.entries) FlairSuggestion(flair: entry.key, contentCount: entry.value),
      ];
      suggestions.sort((first, second) {
        final countComparison = second.contentCount.compareTo(first.contentCount);
        if (countComparison != 0) {
          return countComparison;
        }
        return first.flair.compareTo(second.flair);
      });
      return suggestions.take(limit).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }
}
