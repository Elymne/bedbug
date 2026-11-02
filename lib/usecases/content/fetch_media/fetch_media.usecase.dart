import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/media/media_http/media_http.gateway.dart';
import 'package:bedbug/gateways/media/media_http/media_http.gateway.dio.dart';
import 'package:bedbug/resources/content/trust_settings/safe_url.value_object.dart';
import 'package:bedbug/resources/content/trust_settings/url_trust_policy.value_object.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/trust/url_safety.service.dart';
import 'package:bedbug/services/trust/url_trust.service.dart';
import 'package:bedbug/usecases/content/fetch_media/fetch_media.config.dart';
import 'package:bedbug/usecases/content/fetch_media/fetch_media.failure.dart';
import 'package:bedbug/usecases/content/fetch_media/fetch_media.params.dart';
import 'package:bedbug/usecases/content/fetch_media/fetch_media.result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [FetchMediaUsecase].
final fetchMediaUsecaseProvider = Provider<FetchMediaUsecase>((ref) {
  return FetchMediaUsecase(
    ref.read(mediaHttpGatewayProvider),
    ref.read(urlSafetyServiceProvider),
    ref.read(urlTrustServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Télécharge un média distant, en revérifiant chaque redirection contre la politique de confiance.
///
/// Les listes de domaines ne valent que si elles s'appliquent à chaque
/// requête : un domaine de confiance peut rediriger vers n'importe quel
/// site, et un lecteur qui suit les redirections tout seul contournerait
/// les listes. Ce use case suit lui-même les redirections, une par une, et
/// n'accepte chaque nouvelle adresse que si elle est valide et sur un
/// domaine accepté. C'est le seul point d'entrée pour charger un média.
///
/// Retourne l'adresse finale (celle à passer à un lecteur vidéo) et, si
/// demandé, le contenu du média.
class FetchMediaUsecase extends Usecase<FetchMediaParams, FetchMediaFailure, FetchedMedia> {
  /// Crée un [FetchMediaUsecase].
  FetchMediaUsecase(this._mediaHttpGateway, this._urlSafetyService, this._urlTrustService, this._errorLogRepository);

  final MediaHttpGateway _mediaHttpGateway;

  final UrlSafetyService _urlSafetyService;

  final UrlTrustService _urlTrustService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<FetchMediaFailure, FetchedMedia>> call(FetchMediaParams params) async {
    try {
      var url = _urlSafetyService.parse(params.rawUrl);
      if (url == null) {
        return const Left(FetchMediaFailure.invalidUrl);
      }
      final initialHost = url.host;

      for (var redirectCount = 0; redirectCount <= maxMediaRedirects; redirectCount++) {
        if (!_isAllowed(url!, params, initialHost)) {
          return const Left(FetchMediaFailure.untrustedDomain);
        }

        final response = await _mediaHttpGateway.get(url, maxBytes: params.maxBytes, isBodyNeeded: params.isBodyNeeded);
        switch (response) {
          case MediaHttpBody(:final bytes):
            return Right(FetchedMedia(url: url, bytes: bytes));
          case MediaHttpError(:final kind):
            return Left(switch (kind) {
              MediaHttpErrorKind.notFound => FetchMediaFailure.notFound,
              MediaHttpErrorKind.tooLarge => FetchMediaFailure.tooLarge,
              MediaHttpErrorKind.unavailable => FetchMediaFailure.unavailable,
            });
          case MediaHttpRedirect(:final location):
            url = _resolveRedirect(url, location);
            if (url == null) {
              return const Left(FetchMediaFailure.invalidUrl);
            }
        }
      }
      return const Left(FetchMediaFailure.tooManyRedirects);
    } catch (error, stackTrace) {
      AppLogger.error('FetchMediaUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'FetchMediaUsecase', error: error, stackTrace: stackTrace);
      return const Left(FetchMediaFailure.unavailable);
    }
  }

  /// Indique si [url] peut être contactée.
  ///
  /// Un domaine de la whitelist ou de la greylist est accepté. Un domaine
  /// inconnu ne l'est que si l'utilisateur a confirmé vouloir afficher le
  /// média, et seulement pour le domaine qu'il a confirmé : une redirection
  /// vers un autre domaine inconnu reste refusée.
  bool _isAllowed(SafeUrl url, FetchMediaParams params, String initialHost) {
    return switch (_urlTrustService.evaluate(params.policy, url.url)) {
      UrlTrust.trusted || UrlTrust.grey => true,
      UrlTrust.unknown => params.isConfirmed && url.host == initialHost,
      UrlTrust.invalid => false,
    };
  }

  /// Retourne l'adresse vérifiée vers laquelle redirige [location], relative à [from], ou `null` si elle est refusée.
  ///
  /// L'adresse résolue repasse par [UrlSafetyService.parse] : une redirection
  /// vers `http`, une IP ou une adresse piégée est refusée comme le serait
  /// l'adresse d'origine.
  SafeUrl? _resolveRedirect(SafeUrl from, String location) {
    final resolved = Uri.tryParse(from.url)?.resolve(location);
    if (resolved == null) {
      return null;
    }
    return _urlSafetyService.parse(resolved.toString());
  }
}
