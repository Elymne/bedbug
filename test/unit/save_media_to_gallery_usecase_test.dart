import 'dart:typed_data';

import 'package:bedbug/features/content/domain/gateways/media_gallery_gateway.dart';
import 'package:bedbug/features/content/domain/gateways/media_http_gateway.dart';
import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/media_file_format.dart';
import 'package:bedbug/features/content/domain/object_values/safe_url.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/content/domain/services/domain_rule_service.dart';
import 'package:bedbug/features/content/domain/services/media_format_service.dart';
import 'package:bedbug/features/content/domain/services/url_safety_service.dart';
import 'package:bedbug/features/content/domain/services/url_trust_service.dart';
import 'package:bedbug/features/content/domain/usecases/fetch_media_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_media_to_gallery_usecase.dart';
import 'package:bedbug/shared/exceptions/gallery_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faux serveur : une réponse par adresse, et le journal des tailles maximales demandées.
class _FakeMediaHttpGateway implements MediaHttpGateway {
  _FakeMediaHttpGateway(this.responses);

  /// Réponse renvoyée pour chaque adresse ; toute autre adresse répond 404.
  final Map<String, MediaHttpResponse> responses;

  /// Adresses effectivement contactées, dans l'ordre.
  final List<String> requestedUrls = [];

  /// Taille maximale demandée à chaque requête.
  final List<int> requestedMaxBytes = [];

  @override
  Future<MediaHttpResponse> get(SafeUrl url, {required int maxBytes, required bool isBodyNeeded}) async {
    requestedUrls.add(url.url);
    requestedMaxBytes.add(maxBytes);
    return responses[url.url] ?? const MediaHttpError(MediaHttpErrorKind.notFound);
  }
}

/// Fausse galerie qui réussit, ou échoue avec l'erreur fournie.
class _FakeMediaGalleryGateway implements MediaGalleryGateway {
  _FakeMediaGalleryGateway([this.error]);

  /// Erreur levée à l'enregistrement, `null` pour réussir.
  final Object? error;

  /// Formats des médias enregistrés.
  final List<MediaFileFormat> savedFormats = [];

  @override
  Future<void> save(Uint8List bytes, MediaFileFormat format) async {
    final error = this.error;
    if (error != null) {
      throw error;
    }
    savedFormats.add(format);
  }
}

/// Retourne [prefix] suivi de quelques octets de remplissage.
Uint8List _bytes(List<int> prefix) {
  return Uint8List.fromList([...prefix, 0, 0, 0, 0, 0, 0, 0, 0]);
}

void main() {
  const urlSafetyService = UrlSafetyService();
  const domainRuleService = DomainRuleService(urlSafetyService);
  const urlTrustService = UrlTrustService(urlSafetyService, domainRuleService);
  const mediaFormatService = MediaFormatService();

  const policy = UrlTrustPolicy(
    trustedRules: [DomainRule(host: 'cdn.trusted.com', isIncludingSubdomains: false)],
    greyRules: [DomainRule(host: 'grey.com', isIncludingSubdomains: false)],
  );
  final png = _bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  /// Télécharge [rawUrl] avec le faux serveur [http] puis l'enregistre dans la fausse galerie [gallery], comme le fait
  /// `SaveMediaToGalleryNotifier`, et retourne l'échec du téléchargement ou de l'enregistrement.
  Future<Object?> save(
    _FakeMediaHttpGateway http,
    _FakeMediaGalleryGateway gallery,
    String rawUrl, {
    bool isConfirmed = false,
  }) async {
    final fetched = await FetchMediaUsecase(http, urlSafetyService, urlTrustService)(
      FetchMediaParams(rawUrl: rawUrl, policy: policy, isConfirmed: isConfirmed, maxBytes: maxGalleryMediaBytes),
    );
    final fetchedMedia = fetched.right;
    if (fetchedMedia == null) {
      return fetched.left;
    }
    final result = await SaveMediaToGalleryUsecase(gallery, mediaFormatService)(
      SaveMediaToGalleryParams(bytes: fetchedMedia.bytes),
    );
    return result.left;
  }

  group('reconnaissance du format', () {
    test('reconnaît les images et vidéos courantes à leurs premiers octets', () {
      expect(mediaFormatService.detect(_bytes([0xFF, 0xD8, 0xFF, 0xE0])), MediaFileFormat.jpeg);
      expect(mediaFormatService.detect(png), MediaFileFormat.png);
      expect(mediaFormatService.detect(_bytes('GIF89a'.codeUnits)), MediaFileFormat.gif);
      expect(mediaFormatService.detect(_bytes('GIF87a'.codeUnits)), MediaFileFormat.gif);
      expect(
        mediaFormatService.detect(_bytes([...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WEBP'.codeUnits])),
        MediaFileFormat.webp,
      );
      expect(mediaFormatService.detect(_bytes([0x1A, 0x45, 0xDF, 0xA3])), MediaFileFormat.webm);
      expect(mediaFormatService.detect(_bytes([0, 0, 0, 0x20, ...'ftypisom'.codeUnits])), MediaFileFormat.mp4);
      expect(mediaFormatService.detect(_bytes([0, 0, 0, 0x14, ...'ftypqt  '.codeUnits])), MediaFileFormat.quickTime);
    });

    test("refuse tout ce qui n'est pas une image ou une vidéo acceptée, même déguisé", () {
      final rejected = {
        'page web': '<!DOCTYPE html><html>'.codeUnits,
        'svg (peut contenir du script)': '<svg xmlns="http://www.w3.org/2000/svg">'.codeUnits,
        'exécutable Android (zip)': [0x50, 0x4B, 0x03, 0x04],
        'exécutable Windows': [0x4D, 0x5A, 0x90, 0x00],
        'pdf': '%PDF-1.7'.codeUnits,
        'RIFF sans WEBP (wav)': [...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WAVE'.codeUnits],
        'image HEIC dans un conteneur ISO': [0, 0, 0, 0x18, ...'ftypheic'.codeUnits],
        'GIF tronqué': 'GIF8'.codeUnits,
        'texte commençant par des espaces puis un png': [0x20, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      };
      for (final MapEntry(:key, :value) in rejected.entries) {
        expect(mediaFormatService.detect(_bytes(value)), isNull, reason: key);
      }
      expect(mediaFormatService.detect(Uint8List(0)), isNull, reason: 'fichier vide');
      expect(mediaFormatService.detect(Uint8List.fromList([0xFF, 0xD8])), isNull, reason: 'jpeg tronqué');
      expect(
        mediaFormatService.detect(Uint8List.fromList([0, 0, 0, 0, ...'ftyp'.codeUnits])),
        isNull,
        reason: 'ftyp sans marque',
      );
    });
  });

  test("enregistre une image d'un domaine de confiance, avec la taille maximale de la galerie", () async {
    final http = _FakeMediaHttpGateway({'https://cdn.trusted.com/a.png': MediaHttpBody(png)});
    final gallery = _FakeMediaGalleryGateway();
    expect(await save(http, gallery, 'https://cdn.trusted.com/a.png'), isNull);
    expect(gallery.savedFormats, [MediaFileFormat.png]);
    expect(http.requestedMaxBytes, [maxGalleryMediaBytes]);
  });

  test('enregistre un média de la greylist, comme la visionneuse peut l\'afficher', () async {
    final http = _FakeMediaHttpGateway({'https://grey.com/a.png': MediaHttpBody(png)});
    final gallery = _FakeMediaGalleryGateway();
    expect(await save(http, gallery, 'https://grey.com/a.png'), isNull);
    expect(gallery.savedFormats, [MediaFileFormat.png]);
  });

  test("le format vient des octets, jamais de l'extension de l'adresse", () async {
    final http = _FakeMediaHttpGateway({
      'https://cdn.trusted.com/photo.jpg': MediaHttpBody(_bytes('<html><script>'.codeUnits)),
      'https://cdn.trusted.com/video.mp4': MediaHttpBody(png),
    });
    final gallery = _FakeMediaGalleryGateway();
    expect(await save(http, gallery, 'https://cdn.trusted.com/photo.jpg'), SaveMediaToGalleryFailure.unsupportedFormat);
    expect(await save(http, gallery, 'https://cdn.trusted.com/video.mp4'), isNull);
    expect(gallery.savedFormats, [MediaFileFormat.png]);
  });

  test('applique les mêmes règles que l\'affichage : domaine inconnu, redirection ailleurs, adresse piégée', () async {
    final http = _FakeMediaHttpGateway({
      'https://unknown.com/a.png': MediaHttpBody(png),
      'https://cdn.trusted.com/r': const MediaHttpRedirect('https://evil.com/a.png'),
      'https://evil.com/a.png': MediaHttpBody(png),
    });
    final gallery = _FakeMediaGalleryGateway();
    expect(await save(http, gallery, 'https://unknown.com/a.png'), FetchMediaFailure.untrustedDomain);
    expect(await save(http, gallery, 'https://cdn.trusted.com/r'), FetchMediaFailure.untrustedDomain);
    expect(await save(http, gallery, 'https://cdn.trusted.com@evil.com/a.png'), FetchMediaFailure.invalidUrl);
    expect(http.requestedUrls, ['https://cdn.trusted.com/r']);
    expect(gallery.savedFormats, isEmpty);

    // Un domaine inconnu dévoilé par l'utilisateur peut être enregistré.
    expect(await save(http, gallery, 'https://unknown.com/a.png', isConfirmed: true), isNull);
  });

  test('distingue un média trop lourd, un refus d\'accès et les autres échecs', () async {
    final http = _FakeMediaHttpGateway({
      'https://cdn.trusted.com/big.mp4': const MediaHttpError(MediaHttpErrorKind.tooLarge),
      'https://cdn.trusted.com/a.png': MediaHttpBody(png),
    });
    expect(await save(http, _FakeMediaGalleryGateway(), 'https://cdn.trusted.com/big.mp4'), FetchMediaFailure.tooLarge);
    expect(
      await save(
        http,
        _FakeMediaGalleryGateway(const GalleryException('test', 'denied', isAccessDenied: true)),
        'https://cdn.trusted.com/a.png',
      ),
      SaveMediaToGalleryFailure.accessDenied,
    );
    expect(
      await save(
        http,
        _FakeMediaGalleryGateway(const GalleryException('test', 'full')),
        'https://cdn.trusted.com/a.png',
      ),
      SaveMediaToGalleryFailure.saveError,
    );
    expect(
      await save(http, _FakeMediaGalleryGateway(StateError('boom')), 'https://cdn.trusted.com/a.png'),
      SaveMediaToGalleryFailure.saveError,
    );
  });
}
