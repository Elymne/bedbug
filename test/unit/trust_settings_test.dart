import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.config.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.model.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const imgur = DomainRule(host: 'imgur.com', isIncludingSubdomains: true);
  const settings = TrustSettings(
    mediaPolicy: UrlTrustPolicy(
      trustedRules: [imgur],
      greyRules: [DomainRule(host: 'grey.com', isIncludingSubdomains: false)],
    ),
    linkPolicy: UrlTrustPolicy(
      trustedRules: [DomainRule(host: 'github.com', isIncludingSubdomains: false)],
      greyRules: [],
    ),
  );

  group('masquage des contenus', () {
    test('garde un contenu dont toutes les adresses sont de confiance ou en greylist', () {
      expect(
        TrustSettings.isContentHidden(settings, mediaUrls: ['https://i.imgur.com/a.png', 'https://grey.com/b.png']),
        isFalse,
      );
      expect(TrustSettings.isContentHidden(settings, linkUrls: ['https://github.com/x']), isFalse);
      expect(TrustSettings.isContentHidden(settings), isFalse);
    });

    test('masque un contenu dès qu\'une seule adresse vise un domaine absent des listes', () {
      expect(
        TrustSettings.isContentHidden(settings, mediaUrls: ['https://i.imgur.com/a.png', 'https://evil.com/b.png']),
        isTrue,
      );
      expect(TrustSettings.isContentHidden(settings, linkUrls: ['https://flutter.dev']), isTrue);
    });

    test('masque toujours un contenu dont une adresse est piégée', () {
      for (final url in ['https://i.imgur.com@evil.com/a.png', 'http://i.imgur.com/a.png', 'javascript:alert(1)']) {
        expect(TrustSettings.isContentHidden(settings, mediaUrls: [url]), isTrue, reason: url);
        expect(TrustSettings.isContentHidden(settings, linkUrls: [url]), isTrue, reason: url);
      }
    });

    test('chaque famille a sa propre politique : un domaine de liens ne vaut pas pour les médias', () {
      expect(TrustSettings.isContentHidden(settings, mediaUrls: ['https://github.com/a.png']), isTrue);
      expect(TrustSettings.isContentHidden(settings, linkUrls: ['https://i.imgur.com/a']), isTrue);
    });
  });

  group('modification des listes', () {
    test("ranger une règle dans une liste la retire de l'autre, sans doublon", () {
      final moved = TrustSettings.withRule(settings, UrlFamily.media, TrustLevel.grey, imgur);
      expect(moved.mediaPolicy.trustedRules, isEmpty);
      expect(moved.mediaPolicy.greyRules, contains(imgur));

      final twice = TrustSettings.withRule(moved, UrlFamily.media, TrustLevel.grey, imgur);
      expect(twice.mediaPolicy.greyRules.where((rule) => rule == imgur).length, 1);
      // L'autre famille n'est pas touchée.
      expect(twice.linkPolicy.trustedRules, settings.linkPolicy.trustedRules);
    });

    test('retirer une règle la retire de ses deux listes', () {
      final removed = TrustSettings.withoutRule(settings, UrlFamily.media, imgur);
      expect(removed.mediaPolicy.trustedRules, isEmpty);
      expect(UrlTrustPolicy.evaluate(removed.mediaPolicy, 'https://i.imgur.com/a.png'), UrlTrust.unknown);
    });
  });

  group('stockage', () {
    test('relit à l\'identique les réglages enregistrés', () {
      final model = TrustSettingsHiveModel.fromEntity(defaultTrustSettings);
      final reread = model.toEntity();
      expect(reread.mediaPolicy.trustedRules, defaultTrustSettings.mediaPolicy.trustedRules);
      expect(reread.mediaPolicy.greyRules, defaultTrustSettings.mediaPolicy.greyRules);
      expect(reread.linkPolicy.trustedRules, defaultTrustSettings.linkPolicy.trustedRules);
    });

    test('ignore à la relecture une règle stockée qui ne passe plus les vérifications', () {
      final model = TrustSettingsHiveModel(
        mediaTrustedPatterns: ['imgur.com', 'іmgur.com', '127.0.0.1', '*.com'],
        mediaGreyPatterns: [],
        linkTrustedPatterns: [],
        linkGreyPatterns: [],
      );
      final reread = model.toEntity();
      expect(reread.mediaPolicy.trustedRules, [const DomainRule(host: 'imgur.com', isIncludingSubdomains: false)]);
    });
  });

  test('déduit la nature d\'un média de son extension', () {
    expect(ContentMedia.kindOf('https://a.io/x.MP4'), MediaKind.video);
    expect(ContentMedia.kindOf('https://a.io/x.webm?t=1'), MediaKind.video);
    expect(ContentMedia.kindOf('https://a.io/x.gif'), MediaKind.gif);
    expect(ContentMedia.kindOf('https://a.io/x.jpg'), MediaKind.image);
    expect(ContentMedia.kindOf('https://a.io/x.gif.exe'), MediaKind.image);
    expect(ContentMedia.kindOf('pas une url'), MediaKind.image);
  });
}
