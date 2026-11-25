import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/content_url.entity.summary.dart';
import 'package:bedbug/infra/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/link_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/media_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.repository.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.repository.drift.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.repository.drift.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.params.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.usecase.dart';
import 'package:bedbug/logic/usecases/feed/mark_content_viewed/mark_content_viewed.params.dart';
import 'package:bedbug/logic/usecases/feed/mark_content_viewed/mark_content_viewed.usecase.dart';
import 'package:bedbug/logic/usecases/trust/delete_untrusted_contents/delete_untrusted_contents.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Construit un contenu lien d'identifiant [id].
///
/// - [id] : identifiant du contenu.
/// - [url] : adresse du lien.
/// - [origin] : provenance du contenu.
LinkContent _buildLink(String id, String url, {ContentOrigin origin = ContentOrigin.public}) {
  return LinkContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: origin,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre',
    url: url,
  );
}

/// Construit un contenu texte d'identifiant [id], sans aucune adresse.
///
/// - [id] : identifiant du contenu.
TextContent _buildText(String id) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: ContentOrigin.public,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre',
    body: 'Corps',
  );
}

/// Construit un contenu média d'identifiant [id], avec une seule image.
///
/// - [id] : identifiant du contenu.
/// - [url] : adresse de l'image.
/// - [origin] : provenance du contenu.
MediaContent _buildMedia(String id, String url, {ContentOrigin origin = ContentOrigin.public}) {
  return MediaContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: origin,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    media: [ContentMedia(url: url, kind: MediaKind.image)],
    title: 'Titre',
  );
}

/// Construit un contenu dessiné d'identifiant [id], sans aucune adresse.
///
/// - [id] : identifiant du contenu.
DrawingContent _buildDrawing(String id) {
  return DrawingContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: ContentOrigin.public,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    drawing: const Drawing.empty(),
    title: 'Titre',
  );
}

/// Faux [TrustSettingsRepository] dont la lecture échoue.
class _FailingTrustSettingsRepository implements TrustSettingsRepository {
  @override
  Future<TrustSettings?> get() async {
    throw const DatasourceException('test', 'lecture impossible');
  }

  @override
  Future<void> save(TrustSettings settings) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  late ProviderContainer container;

  const settings = TrustSettings(
    mediaPolicy: UrlTrustPolicy(trustedRules: [], greyRules: []),
    linkPolicy: UrlTrustPolicy(
      trustedRules: [DomainRule(host: 'github.com', isIncludingSubdomains: false)],
      greyRules: [DomainRule(host: 'reddit.com', isIncludingSubdomains: false)],
    ),
  );

  setUp(() async {
    container = createTestContainer();
    await container.read(trustSettingsRepositoryProvider).save(settings);
  });

  tearDown(() async {
    container.dispose();
  });

  /// Enregistre [contents] avec le vrai repository.
  Future<void> saveAll(List<Content> contents) async {
    for (final content in contents) {
      await container.read(saveContentUsecaseProvider)(SaveContentParams(content: content));
    }
  }

  /// Retourne les identifiants des contenus restés sur le téléphone.
  Future<Set<String>> remainingIds() async {
    final contents = await container.read(contentRepositoryProvider).getAll();
    return contents.map((content) => content.id).toSet();
  }

  test('supprime un contenu reçu d\'un domaine absent des listes, garde whitelist, greylist et texte', () async {
    await saveAll([
      _buildLink('inconnu', 'https://evil.com/a'),
      _buildLink('confiance', 'https://github.com/a'),
      _buildLink('grey', 'https://reddit.com/a'),
      _buildText('texte'),
    ]);

    final deleted = await container.read(deleteUntrustedContentsUsecaseProvider)(const NoParams());

    expect(deleted.right, 1);
    expect(await remainingIds(), {'confiance', 'grey', 'texte'});
  });

  test('ne supprime jamais les contenus de l\'utilisateur', () async {
    await saveAll([_buildLink('mien', 'https://evil.com/a', origin: ContentOrigin.owned)]);

    final deleted = await container.read(deleteUntrustedContentsUsecaseProvider)(const NoParams());

    expect(deleted.right, 0);
    expect(await remainingIds(), {'mien'});
  });

  test('mémorise le contenu supprimé comme déjà reçu, et l\'oublie des contenus vus', () async {
    await saveAll([_buildLink('inconnu', 'https://evil.com/a')]);
    await container.read(markContentViewedUsecaseProvider)(const MarkContentViewedParams(contentId: 'inconnu'));

    await container.read(deleteUntrustedContentsUsecaseProvider)(const NoParams());

    expect(await container.read(seenContentRepositoryProvider).getSeenAmong({'inconnu'}), {'inconnu'});
    expect(await container.read(viewedContentRepositoryProvider).getAllIds(), isEmpty);
  });

  test('ne supprime rien si les listes ne peuvent pas être lues', () async {
    await saveAll([_buildLink('inconnu', 'https://evil.com/a')]);
    final failingContainer = createTestContainer(
      overrides: [trustSettingsRepositoryProvider.overrideWithValue(_FailingTrustSettingsRepository())],
    );
    addTearDown(failingContainer.dispose);

    final deleted = await failingContainer.read(deleteUntrustedContentsUsecaseProvider)(const NoParams());

    expect(deleted.isSuccess, isFalse);
    expect(await remainingIds(), {'inconnu'});
  });

  test(
    'supprime un média reçu d\'un domaine absent des listes, garde le média de l\'utilisateur et le dessin',
    () async {
      await saveAll([
        _buildMedia('media-inconnu', 'https://evil.com/a.png'),
        _buildMedia('media-mien', 'https://evil.com/b.png', origin: ContentOrigin.owned),
        _buildDrawing('dessin'),
      ]);

      final deleted = await container.read(deleteUntrustedContentsUsecaseProvider)(const NoParams());

      expect(deleted.right, 1);
      expect(await remainingIds(), {'media-mien', 'dessin'});
    },
  );

  test('ne lit que les adresses des liens et médias reçus', () async {
    await saveAll([
      _buildLink('lien', 'https://evil.com/a'),
      _buildLink('lien-mien', 'https://evil.com/b', origin: ContentOrigin.owned),
      _buildMedia('media', 'https://evil.com/c.png'),
      _buildText('texte'),
      _buildDrawing('dessin'),
    ]);

    final summaries = await container.read(contentRepositoryProvider).getReceivedUrlSummaries();

    expect(summaries.toSet(), {
      const ContentUrlSummary(contentId: 'lien', mediaUrls: [], linkUrls: ['https://evil.com/a']),
      const ContentUrlSummary(contentId: 'media', mediaUrls: ['https://evil.com/c.png'], linkUrls: []),
    });
  });
}
