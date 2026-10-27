import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/trust/domain/object_values/default_trust_settings.dart';
import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/trust/infrastructure/models/trust_settings_hive_model.dart';
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
    unknownDomainBehavior: UnknownDomainBehavior.hidden,
  );

  group('masquage des contenus', () {
    test('garde un contenu dont toutes les adresses sont de confiance ou en greylist', () {
      expect(settings.isContentHidden(mediaUrls: ['https://i.imgur.com/a.png', 'https://grey.com/b.png']), isFalse);
      expect(settings.isContentHidden(linkUrls: ['https://github.com/x']), isFalse);
      expect(settings.isContentHidden(), isFalse);
    });

    test('masque un contenu dont une seule adresse vise un domaine inconnu, si le réglage le demande', () {
      expect(settings.isContentHidden(mediaUrls: ['https://i.imgur.com/a.png', 'https://evil.com/b.png']), isTrue);
      expect(settings.isContentHidden(linkUrls: ['https://flutter.dev']), isTrue);
      final blurred = settings.withUnknownDomainBehavior(UnknownDomainBehavior.blurred);
      expect(blurred.isContentHidden(mediaUrls: ['https://evil.com/b.png']), isFalse);
    });

    test('masque toujours un contenu dont une adresse est piégée, quel que soit le réglage', () {
      final blurred = settings.withUnknownDomainBehavior(UnknownDomainBehavior.blurred);
      for (final url in ['https://i.imgur.com@evil.com/a.png', 'http://i.imgur.com/a.png', 'javascript:alert(1)']) {
        expect(blurred.isContentHidden(mediaUrls: [url]), isTrue, reason: url);
        expect(blurred.isContentHidden(linkUrls: [url]), isTrue, reason: url);
      }
    });

    test('chaque famille a sa propre politique : un domaine de liens ne vaut pas pour les médias', () {
      expect(settings.isContentHidden(mediaUrls: ['https://github.com/a.png']), isTrue);
      expect(settings.isContentHidden(linkUrls: ['https://i.imgur.com/a']), isTrue);
    });
  });

  group('modification des listes', () {
    test("ranger une règle dans une liste la retire de l'autre, sans doublon", () {
      final moved = settings.withRule(UrlFamily.media, TrustLevel.grey, imgur);
      expect(moved.mediaPolicy.trustedRules, isEmpty);
      expect(moved.mediaPolicy.greyRules, contains(imgur));

      final twice = moved.withRule(UrlFamily.media, TrustLevel.grey, imgur);
      expect(twice.mediaPolicy.greyRules.where((rule) => rule == imgur).length, 1);
      // L'autre famille n'est pas touchée.
      expect(twice.linkPolicy.trustedRules, settings.linkPolicy.trustedRules);
    });

    test('retirer une règle la retire de ses deux listes', () {
      final removed = settings.withoutRule(UrlFamily.media, imgur);
      expect(removed.mediaPolicy.trustedRules, isEmpty);
      expect(removed.mediaPolicy.evaluate('https://i.imgur.com/a.png'), UrlTrust.unknown);
    });
  });

  group('stockage', () {
    test('relit à l\'identique les réglages enregistrés', () {
      final model = TrustSettingsHiveModel.fromEntity(defaultTrustSettings);
      final reread = model.toEntity();
      expect(reread.mediaPolicy.trustedRules, defaultTrustSettings.mediaPolicy.trustedRules);
      expect(reread.mediaPolicy.greyRules, defaultTrustSettings.mediaPolicy.greyRules);
      expect(reread.linkPolicy.trustedRules, defaultTrustSettings.linkPolicy.trustedRules);
      expect(reread.unknownDomainBehavior, defaultTrustSettings.unknownDomainBehavior);
    });

    test('ignore à la relecture une règle stockée qui ne passe plus les vérifications', () {
      final model = TrustSettingsHiveModel(
        mediaTrustedPatterns: ['imgur.com', 'іmgur.com', '127.0.0.1', '*.com'],
        mediaGreyPatterns: [],
        linkTrustedPatterns: [],
        linkGreyPatterns: [],
        unknownDomainBehavior: 99,
      );
      final reread = model.toEntity();
      expect(reread.mediaPolicy.trustedRules, [const DomainRule(host: 'imgur.com', isIncludingSubdomains: false)]);
      // Une valeur inconnue retombe sur le comportement le plus prudent.
      expect(reread.unknownDomainBehavior, UnknownDomainBehavior.hidden);
    });
  });

  test('déduit la nature d\'un média de son extension', () {
    expect(MediaKind.fromUrl('https://a.io/x.MP4'), MediaKind.video);
    expect(MediaKind.fromUrl('https://a.io/x.webm?t=1'), MediaKind.video);
    expect(MediaKind.fromUrl('https://a.io/x.gif'), MediaKind.gif);
    expect(MediaKind.fromUrl('https://a.io/x.jpg'), MediaKind.image);
    expect(MediaKind.fromUrl('https://a.io/x.gif.exe'), MediaKind.image);
    expect(MediaKind.fromUrl('pas une url'), MediaKind.image);
  });
}
