import 'dart:typed_data';

import 'package:bedbug/features/content/domain/gateways/media_http_gateway.dart';
import 'package:bedbug/features/content/domain/object_values/safe_url.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/content/domain/services/url_safety_service.dart';
import 'package:bedbug/features/content/domain/services/url_trust_service.dart';
import 'package:bedbug/features/content/infrastructure/gateways/dio_media_http_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal de redirections suivies avant d'abandonner.
///
/// Un hébergeur sérieux redirige une ou deux fois (vers son CDN) : au-delà,
/// c'est une boucle ou une chaîne fabriquée pour égarer les vérifications.
const int maxMediaRedirects = 5;

/// Taille maximale d'une image ou d'un gif téléchargé, en octets.
///
/// Borne la mémoire et les données consommées, quoi qu'annonce le serveur.
const int maxImageBytes = 15 * 1024 * 1024;

/// Provider du [FetchMediaUsecase].
final fetchMediaUsecaseProvider = Provider<FetchMediaUsecase>((ref) {
  return FetchMediaUsecase(
    ref.read(mediaHttpGatewayProvider),
    ref.read(urlSafetyServiceProvider),
    ref.read(urlTrustServiceProvider),
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
  FetchMediaUsecase(this._mediaHttpGateway, this._urlSafetyService, this._urlTrustService);

  final MediaHttpGateway _mediaHttpGateway;

  final UrlSafetyService _urlSafetyService;

  final UrlTrustService _urlTrustService;

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

/// Échecs possibles du [FetchMediaUsecase].
enum FetchMediaFailure {
  /// L'adresse, d'origine ou de redirection, est piégée ou mal formée.
  invalidUrl,

  /// L'adresse, d'origine ou de redirection, vise un domaine non accepté.
  untrustedDomain,

  /// Trop de redirections successives.
  tooManyRedirects,

  /// Le média n'existe pas.
  notFound,

  /// Le média dépasse la taille maximale acceptée.
  tooLarge,

  /// Serveur ou réseau indisponible, ou erreur inattendue.
  unavailable,
}

/// Paramètres du [FetchMediaUsecase].
class FetchMediaParams extends Params {
  /// Crée des [FetchMediaParams].
  ///
  /// - [rawUrl] : adresse du média, telle que reçue.
  /// - [policy] : politique de confiance des médias de l'utilisateur.
  /// - [isConfirmed] : `true` si l'utilisateur a confirmé vouloir afficher ce média malgré un domaine inconnu.
  /// - [isBodyNeeded] : `false` pour seulement vérifier l'adresse finale (vidéo lue ensuite par le lecteur).
  /// - [maxBytes] : taille maximale acceptée (défaut [maxImageBytes]).
  const FetchMediaParams({
    required this.rawUrl,
    required this.policy,
    this.isConfirmed = false,
    this.isBodyNeeded = true,
    this.maxBytes = maxImageBytes,
  });

  /// Adresse du média, telle que reçue.
  final String rawUrl;

  /// Politique de confiance des médias de l'utilisateur.
  final UrlTrustPolicy policy;

  /// Indique si l'utilisateur a confirmé vouloir afficher ce média malgré un domaine inconnu.
  final bool isConfirmed;

  /// Indique si le contenu du média doit être téléchargé.
  final bool isBodyNeeded;

  /// Taille maximale acceptée, en octets.
  final int maxBytes;
}

/// Média téléchargé par le [FetchMediaUsecase].
class FetchedMedia {
  /// Crée un [FetchedMedia].
  ///
  /// - [url] : adresse finale, après redirections.
  /// - [bytes] : contenu du média, vide s'il n'était pas demandé.
  const FetchedMedia({required this.url, required this.bytes});

  /// Adresse finale, après redirections vérifiées.
  final SafeUrl url;

  /// Contenu du média, vide s'il n'était pas demandé.
  final Uint8List bytes;
}
