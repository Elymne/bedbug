import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.exception.dart';
import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.gateway.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';
import 'package:bedbug/usecases/content/fetch_link_preview/fetch_link_preview.failure.dart';
import 'package:bedbug/usecases/content/fetch_link_preview/fetch_link_preview.params.dart';
import 'package:bedbug/usecases/content/fetch_link_preview/fetch_link_preview.usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_error_log_repository.dart';

/// Faux site : renvoie [metadata], ou échoue si [isFailing], et garde la trace des pages contactées.
class _FakeOgMetadataGateway implements OgMetadataGateway {
  _FakeOgMetadataGateway({this.isFailing = false});

  /// Indique si la lecture de la page échoue.
  final bool isFailing;

  /// Aperçu renvoyé pour toute page.
  static const metadata = OgMetadata(title: 'Titre', description: 'Description', imageUrl: 'https://site.com/a.png');

  /// Pages effectivement contactées, dans l'ordre.
  final List<String> requestedUrls = [];

  @override
  Future<OgMetadata> fetch(SafeUrl url) async {
    requestedUrls.add(url.url);
    if (isFailing) {
      throw const OgMetadataException('_FakeOgMetadataGateway', 'timeout');
    }
    return metadata;
  }
}

void main() {
  const policy = UrlTrustPolicy(
    trustedRules: [DomainRule(host: 'site.com', isIncludingSubdomains: true)],
    greyRules: [DomainRule(host: 'grey.com', isIncludingSubdomains: false)],
  );

  /// Lance le use case sur [rawUrl] avec le faux site [gateway].
  Future<(FetchLinkPreviewFailure?, OgMetadata?)> fetch(_FakeOgMetadataGateway gateway, String rawUrl) async {
    final usecase = FetchLinkPreviewUsecase(gateway, FakeErrorLogRepository());
    final result = await usecase(FetchLinkPreviewParams(rawUrl: rawUrl, policy: policy));
    return (result.left, result.right);
  }

  test('lit l\'aperçu d\'un lien de la whitelist', () async {
    final gateway = _FakeOgMetadataGateway();

    final (failure, metadata) = await fetch(gateway, 'https://www.site.com/article');

    expect(failure, isNull);
    expect(metadata!.title, 'Titre');
    expect(gateway.requestedUrls, ['https://www.site.com/article']);
  });

  test('ne contacte pas un domaine hors de la whitelist', () async {
    final gateway = _FakeOgMetadataGateway();

    final (greyFailure, _) = await fetch(gateway, 'https://grey.com/page');
    final (unknownFailure, _) = await fetch(gateway, 'https://inconnu.com/page');

    expect(greyFailure, FetchLinkPreviewFailure.untrustedDomain);
    expect(unknownFailure, FetchLinkPreviewFailure.untrustedDomain);
    expect(gateway.requestedUrls, isEmpty);
  });

  test('refuse une adresse mal formée sans rien contacter', () async {
    final gateway = _FakeOgMetadataGateway();

    final (failure, _) = await fetch(gateway, 'http://site.com/page');

    expect(failure, FetchLinkPreviewFailure.invalidUrl);
    expect(gateway.requestedUrls, isEmpty);
  });

  test('signale une page illisible', () async {
    final (failure, _) = await fetch(_FakeOgMetadataGateway(isFailing: true), 'https://site.com/page');

    expect(failure, FetchLinkPreviewFailure.unavailable);
  });
}
