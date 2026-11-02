import 'dart:io';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/resources/content/content/link_content.entity.dart';
import 'package:bedbug/resources/content/content/text_content.entity.dart';
import 'package:bedbug/resources/content/domain_rule/domain_rule.value_object.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.repository.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.repository.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.repository.hive.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/usecases/content/save_content/save_content.params.dart';
import 'package:bedbug/usecases/content/save_content/save_content.usecase.dart';
import 'package:bedbug/usecases/feed/mark_content_viewed/mark_content_viewed.params.dart';
import 'package:bedbug/usecases/feed/mark_content_viewed/mark_content_viewed.usecase.dart';
import 'package:bedbug/usecases/trust/delete_untrusted_contents/delete_untrusted_contents.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

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
  late Directory tempDir;
  late ProviderContainer container;

  const settings = TrustSettings(
    mediaPolicy: UrlTrustPolicy(trustedRules: [], greyRules: []),
    linkPolicy: UrlTrustPolicy(
      trustedRules: [DomainRule(host: 'github.com', isIncludingSubdomains: false)],
      greyRules: [DomainRule(host: 'reddit.com', isIncludingSubdomains: false)],
    ),
  );

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();
    await container.read(trustSettingsRepositoryProvider).save(settings);
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
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
    final failingContainer = ProviderContainer(
      overrides: [trustSettingsRepositoryProvider.overrideWithValue(_FailingTrustSettingsRepository())],
    );
    addTearDown(failingContainer.dispose);

    final deleted = await failingContainer.read(deleteUntrustedContentsUsecaseProvider)(const NoParams());

    expect(deleted.isSuccess, isFalse);
    expect(await remainingIds(), {'inconnu'});
  });
}
