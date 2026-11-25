import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.entity.dart';
import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.repository.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom du repository, repris dans ses exceptions.
const String _source = 'DriftViewedContentRepository';

/// Provider du [DriftViewedContentRepository].
final viewedContentRepositoryProvider = Provider<ViewedContentRepository>((ref) {
  return DriftViewedContentRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [ViewedContentRepository] sur la table `viewed_contents`, dont les lignes partent avec leur
/// contenu par clé étrangère.
class DriftViewedContentRepository implements ViewedContentRepository {
  /// Crée un [DriftViewedContentRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftViewedContentRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Voir [ViewedContentRepository.getAllIds].
  @override
  Future<Set<String>> getAllIds() {
    return guardDrift(_source, () async {
      final viewedContents = _database.viewedContents;
      final query = _database.selectOnly(viewedContents)..addColumns([viewedContents.id]);
      return {for (final row in await query.get()) row.read(viewedContents.id)!};
    });
  }

  /// La première vue est gardée : la remplacer par une vue récente ferait repasser un contenu dans le groupe des non
  /// vus d'un fil en cours de lecture, figé sur les vues antérieures à son début.
  @override
  Future<void> addOne(ViewedContent entity) {
    return guardDrift(_source, () async {
      await _database
          .into(_database.viewedContents)
          .insert(ViewedContentDriftMapper.toCompanion(entity), mode: InsertMode.insertOrIgnore);
    });
  }
}
