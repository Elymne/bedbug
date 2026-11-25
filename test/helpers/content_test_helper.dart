import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enregistre un contenu texte minimal pour chacun de [ids].
///
/// Une réaction ou un commentaire n'existe que sur un contenu présent (clé étrangère) : les tests qui ne portent que
/// sur eux créent d'abord le contenu auquel ils se rattachent.
///
/// - [container] : conteneur du test, branché sur sa base en mémoire.
/// - [ids] : identifiants des contenus à créer.
Future<void> addTestContents(ProviderContainer container, List<String> ids) async {
  await container.read(contentRepositoryProvider).addMany([
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
