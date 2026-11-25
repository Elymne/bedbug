import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.converters.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/common.dart';

part 'drift.database.g.dart';

/// Base de l'app, ouverte au premier accès dans un isolate d'arrière-plan et fermée avec le conteneur de providers.
///
/// Les tests la surchargent avec une base en mémoire.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(
    driftDatabase(
      name: databaseName,
      native: const DriftNativeOptions(setup: configureSqlite),
    ),
  );
  ref.onDispose(database.close);
  return database;
});

/// Réglages bruts de SQLite, appliqués à l'ouverture de chaque connexion, avant toute requête de drift.
///
/// `auto_vacuum` doit être fixé avant la création de la première table : il permet au fichier de rétrécir après de
/// grosses suppressions, sans quoi le poids réel de la base, qui sert de poids utilisé du stockage, ne baisserait
/// jamais. Les clés étrangères, désactivées par défaut dans SQLite, portent les suppressions en cascade.
///
/// Fonction de premier niveau : drift l'envoie à l'isolate de la base.
///
/// [database] : connexion SQLite brute.
void configureSqlite(CommonDatabase database) {
  database.execute('PRAGMA auto_vacuum = INCREMENTAL');
  database.execute('PRAGMA foreign_keys = ON');
}

/// Base SQLite de l'app : toutes les tables, déclarées en SQL dans les fichiers `.table.drift` de chaque ressource.
@DriftDatabase(
  include: {
    'content/comment/comment.table.drift',
    'content/content/content.table.drift',
    'content/drawing/drawing_draft.table.drift',
    'content/reaction/reaction.table.drift',
    'content/seen_content/seen_content.table.drift',
    'content/storage/storage.table.drift',
    'content/trust_settings/trust_settings.table.drift',
    'content/viewed_content/viewed_content.table.drift',
    'error_log/error_log/error_log.table.drift',
    'exchange/exchange_log/exchange_log.table.drift',
    'settings/user_settings/user_settings.table.drift',
    'signature/signature/signature.table.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  /// Crée la base sur la connexion donnée : un fichier en production, une base en mémoire dans les tests.
  ///
  /// [executor] : connexion SQLite sur laquelle drift exécute les requêtes.
  AppDatabase(super.executor);

  /// Version du schéma : à incrémenter, avec une étape de migration, à chaque changement d'un fichier `.table.drift`.
  @override
  int get schemaVersion {
    return 1;
  }

  /// Crée toutes les tables et tous les index au premier lancement.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
    );
  }

  /// Poids réel des données de la base, en octets : les pages occupées, sans les pages libérées par des suppressions.
  ///
  /// C'est le poids utilisé du stockage. Il compte tout ce qui est réellement écrit sur le disque (contenus, dessins,
  /// signatures, réactions, index, journaux), là où la somme des poids des contenus n'en compterait qu'une partie.
  Future<int> usedSizeInBytes() async {
    final row = await customSelect(
      'SELECT (page_count - freelist_count) * page_size AS used_size '
      'FROM pragma_page_count(), pragma_freelist_count(), pragma_page_size()',
    ).getSingle();
    return row.read<int>('used_size');
  }

  /// Rend au système les pages libérées par les dernières suppressions, pour que le fichier rétrécisse.
  ///
  /// À appeler après une suppression massive (limite de stockage, vidage des contenus).
  Future<void> releaseFreePages() async {
    await customStatement('PRAGMA incremental_vacuum');
  }
}
