import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.exception.dart';
import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.gateway.dart';
import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.gateway.dio.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';
import 'package:bedbug/usecases/content/fetch_link_preview/fetch_link_preview.failure.dart';
import 'package:bedbug/usecases/content/fetch_link_preview/fetch_link_preview.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [FetchLinkPreviewUsecase].
final fetchLinkPreviewUsecaseProvider = Provider<FetchLinkPreviewUsecase>((ref) {
  return FetchLinkPreviewUsecase(ref.read(ogMetadataGatewayProvider), ref.read(errorLogRepositoryProvider));
});

/// Lit l'aperçu (image, titre, description) d'un lien que l'utilisateur s'apprête à publier.
///
/// Un lien avec son aperçu se comprend d'un coup d'œil dans le fil. Mais lire l'aperçu, c'est contacter le site du
/// lien sans que l'auteur ait rien ouvert : le site voit alors l'adresse IP du téléphone. Ce use case ne le fait donc
/// que pour une adresse valide, sur un domaine de la whitelist de liens de l'utilisateur. Un échec n'empêche jamais de
/// publier : l'appelant publie simplement le lien sans aperçu.
class FetchLinkPreviewUsecase extends Usecase<FetchLinkPreviewParams, FetchLinkPreviewFailure, OgMetadata> {
  /// Crée un [FetchLinkPreviewUsecase].
  FetchLinkPreviewUsecase(this._ogMetadataGateway, this._errorLogRepository);

  final OgMetadataGateway _ogMetadataGateway;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<FetchLinkPreviewFailure, OgMetadata>> call(FetchLinkPreviewParams params) async {
    try {
      final url = SafeUrl.parse(params.rawUrl);
      if (url == null) {
        return const Left(FetchLinkPreviewFailure.invalidUrl);
      }
      if (UrlTrustPolicy.evaluate(params.policy, url.url) != UrlTrust.trusted) {
        return const Left(FetchLinkPreviewFailure.untrustedDomain);
      }
      return Right(await _ogMetadataGateway.fetch(url));
    } on OgMetadataException catch (error, stackTrace) {
      AppLogger.error('FetchLinkPreviewUsecase', error, stackTrace);
      return const Left(FetchLinkPreviewFailure.unavailable);
    } catch (error, stackTrace) {
      AppLogger.error('FetchLinkPreviewUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'FetchLinkPreviewUsecase', error: error, stackTrace: stackTrace);
      return const Left(FetchLinkPreviewFailure.unknown);
    }
  }
}
