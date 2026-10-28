import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/content/domain/services/domain_rule_service.dart';
import 'package:bedbug/features/content/domain/services/url_safety_service.dart';
import 'package:bedbug/features/content/domain/services/url_trust_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const urlSafetyService = UrlSafetyService();
  const domainRuleService = DomainRuleService(urlSafetyService);
  const urlTrustService = UrlTrustService(urlSafetyService, domainRuleService);

  /// Règle analysée depuis [input], qui doit être valide.
  DomainRule rule(String input) {
    final parsed = domainRuleService.parse(input);
    expect(parsed, isNotNull, reason: 'règle valide attendue : $input');
    return parsed!;
  }

  /// Indique si [input] couvre l'URL [raw], qui doit être valide.
  bool covers(String input, String raw) {
    return domainRuleService.matches(rule(input), urlSafetyService.parse(raw)!);
  }

  group('analyse des règles', () {
    test('accepte un domaine, avec ou sans ses sous-domaines', () {
      expect(rule('i.imgur.com'), const DomainRule(host: 'i.imgur.com', isIncludingSubdomains: false));
      expect(rule('*.imgur.com'), const DomainRule(host: 'imgur.com', isIncludingSubdomains: true));
      expect(domainRuleService.patternOf(rule('*.imgur.com')), '*.imgur.com');
      expect(domainRuleService.patternOf(rule('i.imgur.com')), 'i.imgur.com');
    });

    test('met en minuscules', () {
      expect(rule('I.Imgur.COM'), const DomainRule(host: 'i.imgur.com', isIncludingSubdomains: false));
    });

    test('refuse les saisies mal formées ou piégées', () {
      for (final input in [
        '',
        '   ',
        '*',
        '*.',
        '*.com',
        'com',
        '**.imgur.com',
        'i.*.imgur.com',
        'imgur.*',
        '*imgur.com',
        '.imgur.com',
        'imgur.com.',
        '127.0.0.1',
        'imgur.com/path',
        'imgur.com:443',
        'user@imgur.com',
        'http://imgur.com',
        'https://i.imgur.com@evil.com',
        '\u0456mgur.com', // i cyrillique
        'imgur.\u212Aom', // signe kelvin, qui devient « k » en minuscules
        '\u0130mgur.com', // I pointé turc
        'imgur\u3002com', // point idéographique
        'img\u200Bur.com', // espace sans chasse
        'imgur.com\u0000',
      ]) {
        expect(domainRuleService.parse(input), isNull, reason: 'devrait être refusée : ${Uri.encodeFull(input)}');
      }
    });
  });

  group('correspondance', () {
    test('une règle exacte ne couvre que son domaine', () {
      expect(covers('imgur.com', 'https://imgur.com/a'), isTrue);
      expect(covers('imgur.com', 'https://IMGUR.com/a'), isTrue);
      expect(covers('imgur.com', 'https://i.imgur.com/a'), isFalse);
    });

    test('une règle avec sous-domaines couvre le domaine et ses sous-domaines, à tout niveau', () {
      expect(covers('*.imgur.com', 'https://imgur.com/'), isTrue);
      expect(covers('*.imgur.com', 'https://i.imgur.com/'), isTrue);
      expect(covers('*.imgur.com', 'https://a.b.c.imgur.com/'), isTrue);
    });

    test('compare label par label, jamais sur un simple « se termine par »', () {
      expect(covers('*.imgur.com', 'https://evilimgur.com/'), isFalse);
      expect(covers('*.imgur.com', 'https://evil-imgur.com/'), isFalse);
      expect(covers('*.imgur.com', 'https://imgur.com.evil.com/'), isFalse);
      expect(covers('*.imgur.com', 'https://imgur.co/'), isFalse);
      expect(covers('*.imgur.com', 'https://imgur.community/'), isFalse);
      expect(covers('*.a.example.com', 'https://xa.example.com/'), isFalse);
      expect(covers('imgur.com', 'https://imgur.com.evil.com/'), isFalse);
    });

    test("le domaine cité dans le chemin, la requête ou l'identifiant ne compte pas", () {
      expect(covers('imgur.com', 'https://evil.com/imgur.com'), isFalse);
      expect(covers('imgur.com', 'https://evil.com/?u=https://imgur.com'), isFalse);
      expect(covers('imgur.com', 'https://evil.com#imgur.com'), isFalse);
      expect(urlSafetyService.parse('https://imgur.com@evil.com/'), isNull);
    });

    test('un domaine punycode ne couvre pas sa version latine, et inversement', () {
      expect(covers('*.imgur.com', 'https://xn--mgur-j9e.com/'), isFalse);
      expect(covers('xn--mgur-j9e.com', 'https://imgur.com/'), isFalse);
    });
  });

  group('politique de confiance', () {
    // Règles construites directement : `rule()` appelle `expect`, interdit hors d'un test.
    const policy = UrlTrustPolicy(
      trustedRules: [
        DomainRule(host: 'imgur.com', isIncludingSubdomains: true),
        DomainRule(host: 'media.giphy.com', isIncludingSubdomains: false),
        DomainRule(host: 'example.com', isIncludingSubdomains: true),
      ],
      greyRules: [
        DomainRule(host: 'redd.it', isIncludingSubdomains: true),
        DomainRule(host: 'ads.example.com', isIncludingSubdomains: false),
      ],
    );

    test('classe chaque URL selon les listes', () {
      expect(urlTrustService.evaluate(policy, 'https://i.imgur.com/a.gif'), UrlTrust.trusted);
      expect(urlTrustService.evaluate(policy, 'https://media.giphy.com/x.gif'), UrlTrust.trusted);
      expect(urlTrustService.evaluate(policy, 'https://i.redd.it/x.jpg'), UrlTrust.grey);
      expect(urlTrustService.evaluate(policy, 'https://evil.com/x.gif'), UrlTrust.unknown);
      expect(urlTrustService.evaluate(policy, 'https://giphy.com/x.gif'), UrlTrust.unknown);
    });

    test('en cas de doublon entre les listes, la greylist l\'emporte', () {
      expect(urlTrustService.evaluate(policy, 'https://ads.example.com/x'), UrlTrust.grey);
      expect(urlTrustService.evaluate(policy, 'https://www.example.com/x'), UrlTrust.trusted);
    });

    test('une URL piégée est invalide, même si elle cite un domaine de confiance', () {
      expect(urlTrustService.evaluate(policy, 'https://i.imgur.com@evil.com/a.gif'), UrlTrust.invalid);
      expect(urlTrustService.evaluate(policy, 'http://i.imgur.com/a.gif'), UrlTrust.invalid);
      expect(urlTrustService.evaluate(policy, 'https://\u0456.imgur.com/a.gif'), UrlTrust.invalid);
      expect(urlTrustService.evaluate(policy, 'https://evil.com\\@i.imgur.com/'), UrlTrust.invalid);
      expect(urlTrustService.evaluate(policy, 'javascript:alert(1)//i.imgur.com'), UrlTrust.invalid);
    });

    test('sans aucune règle, tout domaine valide est inconnu', () {
      const empty = UrlTrustPolicy(trustedRules: [], greyRules: []);
      expect(urlTrustService.evaluate(empty, 'https://i.imgur.com/a.gif'), UrlTrust.unknown);
    });
  });
}
