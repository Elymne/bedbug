import 'package:bedbug/features/content/domain/services/url_safety_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const urlSafetyService = UrlSafetyService();

  /// Vérifie que [raw] est refusée.
  void expectRejected(String raw) {
    expect(urlSafetyService.parse(raw), isNull, reason: 'devrait être refusée : ${Uri.encodeFull(raw)}');
  }

  /// Vérifie que [raw] est acceptée et pointe vers [host].
  void expectHost(String raw, String host) {
    final url = urlSafetyService.parse(raw);
    expect(url, isNotNull, reason: 'devrait être acceptée : $raw');
    expect(url!.host, host, reason: raw);
  }

  group('URLs légitimes', () {
    test('accepte une URL https ordinaire, avec chemin, requête et fragment', () {
      expectHost('https://i.imgur.com', 'i.imgur.com');
      expectHost('https://i.imgur.com/', 'i.imgur.com');
      expectHost('https://i.imgur.com/abc123.gif', 'i.imgur.com');
      expectHost('https://media.giphy.com/media/xyz/giphy.gif?cid=1&rid=giphy.gif', 'media.giphy.com');
      expectHost('https://fr.wikipedia.org/wiki/Punaise_de_lit#Biologie', 'fr.wikipedia.org');
      expectHost('https://example.com/caf%C3%A9', 'example.com');
      expectHost('https://example.com?q=1', 'example.com');
      expectHost('https://example.com#top', 'example.com');
      expectHost('https://a-b.example.co.uk/x', 'a-b.example.co.uk');
    });

    test('met le schéma et le domaine en minuscules, et garde le reste tel quel', () {
      final url = urlSafetyService.parse('HTTPS://I.IMGUR.COM/AbC.gif?X=Y');
      expect(url!.host, 'i.imgur.com');
      expect(url.url, 'https://i.imgur.com/AbC.gif?X=Y');
    });

    test('accepte un domaine internationalisé sous sa forme punycode', () {
      expectHost('https://xn--bcher-kva.example/', 'xn--bcher-kva.example');
    });

    test("un '@' ou un domaine dans le chemin, la requête ou le fragment ne change pas le domaine", () {
      expectHost('https://i.imgur.com/@evil.com', 'i.imgur.com');
      expectHost('https://i.imgur.com?@evil.com', 'i.imgur.com');
      expectHost('https://evil.com#@i.imgur.com', 'evil.com');
      expectHost('https://evil.com/https://i.imgur.com', 'evil.com');
      expectHost('https://i.imgur.com//evil.com', 'i.imgur.com');
    });
  });

  group('schéma', () {
    test("refuse tout ce qui n'est pas https", () {
      expectRejected('http://i.imgur.com/a.gif');
      expectRejected('ftp://i.imgur.com/a.gif');
      expectRejected('file:///etc/passwd');
      expectRejected('javascript:alert(1)');
      expectRejected('JaVaScRiPt:alert(1)');
      expectRejected('data:image/png;base64,iVBORw0KGgo=');
      expectRejected('intent://scan/#Intent;scheme=zxing;end');
      expectRejected('content://media/external/images/1');
      expectRejected('//i.imgur.com/a.gif');
      expectRejected('i.imgur.com/a.gif');
    });

    test('refuse un schéma https mal écrit', () {
      expectRejected('https:i.imgur.com');
      expectRejected('https:/i.imgur.com');
      expectRejected('https:///i.imgur.com');
      expectRejected('https://');
      expectRejected('https:// i.imgur.com');
      expectRejected('https\\://i.imgur.com');
      expectRejected('hxxps://i.imgur.com');
    });
  });

  group('identifiants et ports dans la partie domaine', () {
    test('refuse un identifiant avant le domaine, qui ferait contacter un autre site', () {
      expectRejected('https://i.imgur.com@evil.com/');
      expectRejected('https://i.imgur.com:pass@evil.com/');
      expectRejected('https://user@i.imgur.com/');
      expectRejected('https://@i.imgur.com/');
      expectRejected('https://i.imgur.com%40evil.com/');
      expectRejected('https://i.imgur.com%2540evil.com/');
    });

    test('refuse un port explicite, même 443', () {
      expectRejected('https://i.imgur.com:443/');
      expectRejected('https://i.imgur.com:8080/');
      expectRejected('https://i.imgur.com:/');
      expectRejected('https://i.imgur.com:99999999/');
    });
  });

  group('adresses IP et noms locaux', () {
    test('refuse toutes les écritures d\'une adresse IPv4', () {
      expectRejected('https://127.0.0.1/');
      expectRejected('https://192.168.1.1/a.gif');
      expectRejected('https://2130706433/');
      expectRejected('https://0x7f000001/');
      expectRejected('https://0x7f.0x0.0x0.0x1/');
      expectRejected('https://0177.0.0.1/');
      expectRejected('https://127.1/');
    });

    test("un nom de domaine qui ressemble à une IP reste un nom : c'est la whitelist qui le bloque", () {
      // Des services comme nip.io font pointer `127.0.0.1.nip.io` vers
      // 127.0.0.1 : la syntaxe seule ne peut pas le deviner, seule une
      // whitelist (où il ne figurera jamais) le peut.
      expectHost('https://127.0.0.1.nip.io/', '127.0.0.1.nip.io');
    });

    test('refuse une adresse IPv6', () {
      expectRejected('https://[::1]/');
      expectRejected('https://[::ffff:127.0.0.1]/');
      expectRejected('https://[2001:db8::1]:443/');
    });

    test('refuse un nom sans extension', () {
      expectRejected('https://localhost/');
      expectRejected('https://intranet/');
    });
  });

  group('noms de domaine mal formés', () {
    test('refuse les points en trop, en tête ou en fin', () {
      expectRejected('https://i.imgur.com./');
      expectRejected('https://.i.imgur.com/');
      expectRejected('https://i..imgur.com/');
      expectRejected('https://./');
    });

    test('refuse les tirets en début ou fin de label, et les caractères hors syntaxe', () {
      expectRejected('https://-imgur.com/');
      expectRejected('https://imgur-.com/');
      expectRejected('https://i_mgur.com/');
      expectRejected('https://i*mgur.com/');
      expectRejected('https://imgur.com!/');
      expectRejected('https://imgur.c\$om/');
    });

    test('refuse un label de plus de 63 caractères et un domaine de plus de 253', () {
      expectHost('https://${'a' * 63}.com/', '${'a' * 63}.com');
      expectRejected('https://${'a' * 64}.com/');
      final longHost = '${List.filled(63, 'a' * 3).join('.')}.com';
      expect(longHost.length, greaterThan(253));
      expectRejected('https://$longHost/');
    });

    test('refuse une URL trop longue', () {
      expectHost('https://example.com/${'a' * (maxSafeUrlLength - 20)}', 'example.com');
      expectRejected('https://example.com/${'a' * maxSafeUrlLength}');
    });

    test("refuse un domaine encodé en pourcentage, qu'un client pourrait décoder", () {
      expectRejected('https://i%2Eimgur.com/');
      expectRejected('https://%69.imgur.com/');
    });
  });

  group('caractères qui trompent les vérifications de chaînes', () {
    test('refuse les lettres Unicode qui imitent des lettres latines', () {
      expectRejected('https://\u0456mgur.com/'); // i cyrillique
      expectRejected('https://imgur.c\u043Em/'); // o cyrillique
      expectRejected('https://\uFF49mgur.com/'); // i pleine chasse
      expectRejected('https://imgur.\u212Aom/'); // signe kelvin, qui devient « k » en minuscules
      expectRejected('https://\u0131mgur.com/'); // i sans point turc
      expectRejected('https://\u0130mgur.com/'); // I pointé turc, qui devient deux caractères en minuscules
      expectRejected('https://bücher.example/');
    });

    test('refuse les points qui ne sont pas des points ASCII', () {
      expectRejected('https://i\u3002imgur.com/'); // point idéographique
      expectRejected('https://i\uFF0Eimgur.com/'); // point pleine chasse
      expectRejected('https://i\uFF61imgur.com/'); // point idéographique demi-chasse
      expectRejected('https://i\u2024imgur.com/'); // point de conduite
    });

    test('refuse les caractères invisibles et les inversions du sens d\'écriture', () {
      expectRejected('https://i.imgur.com\u200B/'); // espace sans chasse
      expectRejected('https://i.img\u200Dur.com/'); // liant sans chasse
      expectRejected('https://\uFEFFi.imgur.com/'); // indicateur d'ordre des octets
      expectRejected('https://i.imgur.com\u00AD/'); // trait d'union conditionnel
      expectRejected('https://moc.rugmi\u202E.evil.com/'); // inversion droite-à-gauche
      expectRejected('https://i.imgur.com/\u202Efig.exe');
      expectRejected('https://i.imgur.com/\u2066x');
    });

    test('refuse les espaces et caractères de contrôle, même en fin de chaîne', () {
      expectRejected(' https://i.imgur.com/');
      expectRejected('https://i.imgur.com/ ');
      expectRejected('https://i.imgur.com/a b');
      expectRejected('https://i.img\tur.com/');
      expectRejected('https://i.imgur.com\n.evil.com/');
      expectRejected('https://i.imgur.com\r\n/');
      expectRejected('https://i.imgur.com\u0000.evil.com/');
      expectRejected('https://i.imgur.com/\u0000');
      expectRejected('https://i.imgur.com/\u007F');
      expectRejected('https://i.imgur.com\u00A0/');
      expectRejected('https://i.imgur.com/\u0085');
    });

    test("refuse l'antislash, que les navigateurs lisent comme un '/'", () {
      expectRejected('https://evil.com\\@i.imgur.com/');
      expectRejected('https://i.imgur.com\\.evil.com/');
      expectRejected('https:\\\\i.imgur.com/');
      expectRejected('https://i.imgur.com/a\\b');
    });

    test('refuse les autres caractères interdits par la RFC 3986', () {
      for (final character in ['"', '<', '>', '^', '`', '{', '|', '}']) {
        expectRejected('https://i.imgur.com/a${character}b');
      }
    });

    test('refuse un pourcentage mal formé', () {
      expectRejected('https://example.com/%');
      expectRejected('https://example.com/%2');
      expectRejected('https://example.com/%zz');
      expectRejected('https://example.com/%%41');
    });

    test('refuse les emojis et les surrogates isolés', () {
      expectRejected('https://i.imgur.com/😀');
      expectRejected('https://😀.com/');
      expectRejected('https://i.imgur.com/\uD800');
    });
  });

  test("l'URL normalisée est elle-même acceptée à l'identique", () {
    for (final raw in [
      'HTTPS://I.IMGUR.COM/AbC.gif',
      'https://example.com/caf%C3%A9?q=1#x',
      'https://a.b.c.example.org',
    ]) {
      final url = urlSafetyService.parse(raw)!;
      expect(urlSafetyService.parse(url.url), url);
    }
  });
}
