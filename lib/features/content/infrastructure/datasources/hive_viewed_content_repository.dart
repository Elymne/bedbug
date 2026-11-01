import 'package:bedbug/features/content/domain/repositories/viewed_content_repository.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Nom de la box Hive des contenus vus par l'utilisateur.
const String viewedContentBoxName = 'viewed_contents';

/// Provider de la [Box] Hive des contenus vus : identifiant du contenu → date de vue en millisecondes.
final hiveViewedContentBoxProvider = Provider<Box<int>>((ref) => Hive.box<int>(viewedContentBoxName));

/// Provider du [HiveViewedContentRepository].
final viewedContentRepositoryProvider = Provider<ViewedContentRepository>((ref) {
  return HiveViewedContentRepository(ref.read(hiveViewedContentBoxProvider));
});

/// Implémentation de [ViewedContentRepository] utilisant Hive.
///
/// Une box à part plutôt qu'un champ du contenu : marquer un contenu comme vu arrive à chaque défilement, et ne doit
/// pas réécrire le contenu entier.
class HiveViewedContentRepository implements ViewedContentRepository {
  /// Crée un [HiveViewedContentRepository].
  HiveViewedContentRepository(this._box);

  final Box<int> _box;

  @override
  Future<Set<String>> getAllIds() async {
    try {
      return _box.keys.cast<String>().toSet();
    } on HiveError catch (error) {
      throw DatasourceException('HiveViewedContentRepository', error);
    }
  }

  @override
  Future<void> add(String id) async {
    try {
      await _box.put(id, DateTime.now().millisecondsSinceEpoch);
    } on HiveError catch (error) {
      throw DatasourceException('HiveViewedContentRepository', error);
    }
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    try {
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveViewedContentRepository', error);
    }
  }
}
