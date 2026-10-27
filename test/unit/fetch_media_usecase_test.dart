import 'dart:typed_data';

import 'package:bedbug/features/trust/domain/gateways/media_http_gateway.dart';
import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/trust/domain/usecases/fetch_media_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faux serveur : une réponse par adresse, et le journal des adresses contactées.
class _FakeMediaHttpGateway implements MediaHttpGateway {
  _FakeMediaHttpGateway(this.responses);

  /// Réponse renvoyée pour chaque adresse ; toute autre adresse répond 404.
  final Map<String, MediaHttpResponse> responses;

  /// Adresses effectivement contactées, dans l'ordre.
  final List<String> requestedUrls = [];

  @override
  Future<MediaHttpResponse> get(SafeUrl url, {required int maxBytes, required bool isBodyNeeded}) async {
    requestedUrls.add(url.url);
    return responses[url.url] ?? const MediaHttpError(MediaHttpErrorKind.notFound);
  }
}

void main() {
  const policy = UrlTrustPolicy(
    trustedRules: [
      DomainRule(host: 'picsum.photos', isIncludingSubdomains: true),
      DomainRule(host: 'cdn.trusted.com', isIncludingSubdomains: false),
    ],
    greyRules: [DomainRule(host: 'grey.com', isIncludingSubdomains: false)],
  );
  final image = MediaHttpBody(Uint8List.fromList([1, 2, 3]));

  /// Lance le use case sur [rawUrl] avec le faux serveur [gateway].
  Future<(FetchMediaFailure?, FetchedMedia?)> fetch(
    _FakeMediaHttpGateway gateway,
    String rawUrl, {
    bool isConfirmed = false,
  }) async {
    final result = await FetchMediaUsecase(gateway)(
      FetchMediaParams(rawUrl: rawUrl, policy: policy, isConfirmed: isConfirmed),
    );
    return (result.left, result.right);
  }

  test('charge un média de confiance sans redirection', () async {
    final gateway = _FakeMediaHttpGateway({'https://picsum.photos/1.jpg': image});
    final (failure, media) = await fetch(gateway, 'https://picsum.photos/1.jpg');
    expect(failure, isNull);
    expect(media!.bytes, [1, 2, 3]);
    expect(media.url.url, 'https://picsum.photos/1.jpg');
  });

  test('suit une redirection vers un domaine de confiance, et retourne l\'adresse finale', () async {
    final gateway = _FakeMediaHttpGateway({
      'https://picsum.photos/1': const MediaHttpRedirect('https://fastly.picsum.photos/1.jpg?hmac=x'),
      'https://fastly.picsum.photos/1.jpg?hmac=x': image,
    });
    final (failure, media) = await fetch(gateway, 'https://picsum.photos/1');
    expect(failure, isNull);
    expect(media!.url.host, 'fastly.picsum.photos');
  });

  test('résout une redirection relative par rapport à l\'adresse courante', () async {
    final gateway = _FakeMediaHttpGateway({
      'https://picsum.photos/a/b': const MediaHttpRedirect('../c.jpg'),
      'https://picsum.photos/c.jpg': image,
    });
    final (failure, _) = await fetch(gateway, 'https://picsum.photos/a/b');
    expect(failure, isNull);
    expect(gateway.requestedUrls.last, 'https://picsum.photos/c.jpg');
  });

  test('refuse une redirection vers un domaine inconnu, sans jamais le contacter', () async {
    final gateway = _FakeMediaHttpGateway({
      'https://picsum.photos/1': const MediaHttpRedirect('https://evil.com/1.jpg'),
      'https://evil.com/1.jpg': image,
    });
    final (failure, _) = await fetch(gateway, 'https://picsum.photos/1');
    expect(failure, FetchMediaFailure.untrustedDomain);
    expect(gateway.requestedUrls, ['https://picsum.photos/1']);
  });

  test('refuse une redirection piégée ou hors https, sans la contacter', () async {
    for (final location in [
      'http://picsum.photos/1.jpg',
      'https://picsum.photos@evil.com/1.jpg',
      'https://127.0.0.1/1.jpg',
      'https://evil.com\\@picsum.photos/1.jpg',
      'javascript:alert(1)',
      'https://picѕum.photos/1.jpg',
      '//evil.com/1.jpg',
    ]) {
      final gateway = _FakeMediaHttpGateway({'https://picsum.photos/1': MediaHttpRedirect(location)});
      final (failure, _) = await fetch(gateway, 'https://picsum.photos/1');
      expect(failure, isNot(isNull), reason: Uri.encodeFull(location));
      expect(gateway.requestedUrls, ['https://picsum.photos/1'], reason: Uri.encodeFull(location));
    }
  });

  test('abandonne une boucle de redirections', () async {
    final gateway = _FakeMediaHttpGateway({
      'https://picsum.photos/a': const MediaHttpRedirect('https://picsum.photos/b'),
      'https://picsum.photos/b': const MediaHttpRedirect('https://picsum.photos/a'),
    });
    final (failure, _) = await fetch(gateway, 'https://picsum.photos/a');
    expect(failure, FetchMediaFailure.tooManyRedirects);
    expect(gateway.requestedUrls.length, maxMediaRedirects + 1);
  });

  test('charge un média de la greylist, qui est un domaine accepté', () async {
    final gateway = _FakeMediaHttpGateway({'https://grey.com/1.png': image});
    expect((await fetch(gateway, 'https://grey.com/1.png')).$1, isNull);
  });

  test("ne contacte un domaine inconnu que si l'utilisateur l'a confirmé", () async {
    final gateway = _FakeMediaHttpGateway({'https://unknown.com/1.png': image});
    expect((await fetch(gateway, 'https://unknown.com/1.png')).$1, FetchMediaFailure.untrustedDomain);
    expect(gateway.requestedUrls, isEmpty);
    expect((await fetch(gateway, 'https://unknown.com/1.png', isConfirmed: true)).$1, isNull);
  });

  test('une confirmation ne vaut que pour le domaine confirmé, pas pour une redirection ailleurs', () async {
    final gateway = _FakeMediaHttpGateway({
      'https://unknown.com/1': const MediaHttpRedirect('https://unknown.com/2.png'),
      'https://unknown.com/2.png': const MediaHttpRedirect('https://other-unknown.com/3.png'),
      'https://other-unknown.com/3.png': image,
    });
    final (failure, _) = await fetch(gateway, 'https://unknown.com/1', isConfirmed: true);
    expect(failure, FetchMediaFailure.untrustedDomain);
    expect(gateway.requestedUrls, ['https://unknown.com/1', 'https://unknown.com/2.png']);
  });

  test("refuse une adresse d'origine piégée sans rien contacter", () async {
    final gateway = _FakeMediaHttpGateway({});
    for (final rawUrl in ['https://picsum.photos@evil.com/1.jpg', 'http://picsum.photos/1.jpg', 'pas une url']) {
      expect((await fetch(gateway, rawUrl, isConfirmed: true)).$1, FetchMediaFailure.invalidUrl);
    }
    expect(gateway.requestedUrls, isEmpty);
  });

  test('traduit les échecs du serveur', () async {
    final gateway = _FakeMediaHttpGateway({
      'https://picsum.photos/big': const MediaHttpError(MediaHttpErrorKind.tooLarge),
      'https://picsum.photos/down': const MediaHttpError(MediaHttpErrorKind.unavailable),
    });
    expect((await fetch(gateway, 'https://picsum.photos/missing')).$1, FetchMediaFailure.notFound);
    expect((await fetch(gateway, 'https://picsum.photos/big')).$1, FetchMediaFailure.tooLarge);
    expect((await fetch(gateway, 'https://picsum.photos/down')).$1, FetchMediaFailure.unavailable);
  });
}
