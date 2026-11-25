import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Remplace la base de l'app par une base SQLite en mémoire, neuve et propre au conteneur qui l'utilise.
///
/// La base est fermée avec le conteneur, ce qui évite à drift de signaler plusieurs bases ouvertes d'un test à l'autre.
Override testDatabaseOverride() {
  return appDatabaseProvider.overrideWith((ref) {
    final database = AppDatabase(NativeDatabase.memory(setup: configureSqlite));
    ref.onDispose(database.close);
    return database;
  });
}

/// Crée un conteneur de providers branché sur une base en mémoire neuve.
///
/// [overrides] : surcharges propres au test, ajoutées après celle de la base.
ProviderContainer createTestContainer({List<Override> overrides = const []}) {
  return ProviderContainer(overrides: [testDatabaseOverride(), ...overrides]);
}
