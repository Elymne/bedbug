import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Règle analysée depuis [input], qui doit être valide.
  DomainRule rule(String input) {
    final parsed = DomainRule.tryParse(input);
    expect(parsed, isNotNull, reason: 'règle valide attendue : $input');
    return parsed!;
  }

  /// Indique si [input] couvre l'URL [raw], qui doit être valide.
  bool covers(String input, String raw) {
    return rule(input).matches(SafeUrl.tryParse(raw)!);
  }

  group('analyse des règles', () {
    test('accepte un domaine, avec ou sans ses sous-domaines', () {
      expect(rule('i.imgur.com'), const DomainRule(host: 'i.imgur.com', isIncludingSubdomains: false));
      expect(rule('*.imgur.com'), const DomainRule(host: 'imgur.com', isIncludingSubdomains: true));
      expect(rule('*.imgur.com').pattern, '*.imgur.com');
    });

    test('nettoie les espaces autour et met en minuscules', () {
      expect(rule('  I.Imgur.COM \n'), const DomainRule(host: 'i.imgur.com', isIncludingSubdomains: false));
    });

    test("d'une URL collée, ne garde que le domaine exact", () {
      expect(
        rule('https://media.giphy.com/media/xyz/giphy.gif'),
        const DomainRule(host: 'media.giphy.com', isIncludingSubdomains: false),
      );
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
        expect(DomainRule.tryParse(input), isNull, reason: 'devrait être refusée : ${Uri.encodeFull(input)}');
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
      expect(SafeUrl.tryParse('https://imgur.com@evil.com/'), isNull);
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
      expect(policy.evaluate('https://i.imgur.com/a.gif'), UrlTrust.trusted);
      expect(policy.evaluate('https://media.giphy.com/x.gif'), UrlTrust.trusted);
      expect(policy.evaluate('https://i.redd.it/x.jpg'), UrlTrust.grey);
      expect(policy.evaluate('https://evil.com/x.gif'), UrlTrust.unknown);
      expect(policy.evaluate('https://giphy.com/x.gif'), UrlTrust.unknown);
    });

    test('en cas de doublon entre les listes, la greylist l\'emporte', () {
      expect(policy.evaluate('https://ads.example.com/x'), UrlTrust.grey);
      expect(policy.evaluate('https://www.example.com/x'), UrlTrust.trusted);
    });

    test('une URL piégée est invalide, même si elle cite un domaine de confiance', () {
      expect(policy.evaluate('https://i.imgur.com@evil.com/a.gif'), UrlTrust.invalid);
      expect(policy.evaluate('http://i.imgur.com/a.gif'), UrlTrust.invalid);
      expect(policy.evaluate('https://\u0456.imgur.com/a.gif'), UrlTrust.invalid);
      expect(policy.evaluate('https://evil.com\\@i.imgur.com/'), UrlTrust.invalid);
      expect(policy.evaluate('javascript:alert(1)//i.imgur.com'), UrlTrust.invalid);
    });

    test('sans aucune règle, tout domaine valide est inconnu', () {
      const empty = UrlTrustPolicy(trustedRules: [], greyRules: []);
      expect(empty.evaluate('https://i.imgur.com/a.gif'), UrlTrust.unknown);
    });
  });
}
