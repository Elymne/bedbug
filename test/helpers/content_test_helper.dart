import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.mapper.drift.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enregistre un contenu texte minimal pour chacun de [ids].
///
/// Une réaction ou un commentaire n'existe que sur un contenu présent (clé étrangère) : les tests qui ne portent que
/// sur eux créent d'abord le contenu auquel ils se rattachent.
///
/// - [container] : conteneur du test, branché sur sa base en mémoire.
/// - [ids] : identifiants des contenus à créer.
Future<void> addTestContents(ProviderContainer container, List<String> ids) async {
  await insertTestContents(container, [
    for (final id in ids)
      TextContent(
        id: id,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        signatureId: 'author',
        flair: 'test',
        origin: ContentOrigin.public,
        broadcastScore: 1,
        survivalScore: 1,
        displayScore: 1,
        bounce: 0,
        sizeInBytes: 10,
        title: 'Titre $id',
        body: 'Corps $id',
      ),
  ]);
}

/// Écrit [contents] directement en base, en un seul lot, comme données de départ d'un test.
///
/// L'app n'enregistre les contenus qu'un par un : préparer un test passe donc par la base, sans ajouter au
/// repository une méthode que seuls les tests utiliseraient. Un contenu de même identifiant est mis à jour sur place.
///
/// - [container] : conteneur du test, branché sur sa base en mémoire.
/// - [contents] : contenus à écrire.
Future<void> insertTestContents(ProviderContainer container, List<Content> contents) async {
  final database = container.read(appDatabaseProvider);
  final storedAt = DateTime.now();
  await database.batch((batch) {
    for (final content in contents) {
      batch.insert(
        database.contents,
        ContentDriftMapper.toCompanion(content, storedAt: storedAt),
        onConflict: DoUpdate((_) => ContentDriftMapper.toCompanion(content)),
      );
    }
  });
}

/// Écrit [reactions] directement en base, en un seul lot, sans passer par les règles de fusion.
///
/// Sert à poser un état de départ précis (plafond atteint, réaction de l'utilisateur…) que les règles de fusion ne
/// laisseraient pas construire réaction par réaction.
///
/// - [container] : conteneur du test, branché sur sa base en mémoire.
/// - [reactions] : réactions à écrire, sur des contenus déjà présents.
Future<void> insertTestReactions(ProviderContainer container, List<Reaction> reactions) async {
  final database = container.read(appDatabaseProvider);
  await database.batch((batch) {
    batch.insertAllOnConflictUpdate(database.reactions, [
      for (final reaction in reactions) ReactionDriftMapper.toCompanion(reaction),
    ]);
  });
}

/// Retourne tous les contenus de la base, dessins compris, sans ordre garanti.
///
/// L'app ne lit jamais la table entière : cette lecture n'existe que pour vérifier l'état de la base après un test.
///
/// - [container] : conteneur du test, branché sur sa base en mémoire.
Future<List<Content>> readTestContents(ProviderContainer container) async {
  final database = container.read(appDatabaseProvider);
  final rows = await database.select(database.contents).get();
  return [for (final row in rows) ContentDriftMapper.toEntity(row)];
}

/// Retourne les identifiants de tous les contenus marqués comme vus à l'écran.
///
/// - [container] : conteneur du test, branché sur sa base en mémoire.
Future<Set<String>> readTestViewedIds(ProviderContainer container) async {
  final database = container.read(appDatabaseProvider);
  final rows = await database.select(database.viewedContents).get();
  return {for (final row in rows) row.id};
}
