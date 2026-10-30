import 'dart:typed_data';

import 'package:bedbug/features/content/domain/object_values/exchange_bundle.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_offer.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_request.dart';

/// Contrat de mise en octets des messages échangés entre deux appareils.
///
/// Le transport (BLE aujourd'hui) ne fait circuler que des octets : ce gateway traduit les objets d'un échange
/// dans le format qui voyage, et inversement. Le format est versionné, pour que deux versions de l'app puissent
/// encore se comprendre ou au moins se reconnaître incompatibles.
///
/// Les décodages ne font confiance à rien : un message mal formé, d'une version inconnue ou trop volumineux une
/// fois décompressé lève une `DataException`.
abstract class ExchangeCodecGateway {
  /// Retourne [offer] encodée.
  Uint8List encodeOffer(ExchangeOffer offer);

  /// Retourne l'offre décodée depuis [bytes].
  ExchangeOffer decodeOffer(Uint8List bytes);

  /// Retourne [request] encodée.
  Uint8List encodeRequest(ExchangeRequest request);

  /// Retourne la demande décodée depuis [bytes].
  ExchangeRequest decodeRequest(Uint8List bytes);

  /// Retourne [bundle] encodé.
  Uint8List encodeBundle(ExchangeBundle bundle);

  /// Retourne le lot décodé depuis [bytes].
  ExchangeBundle decodeBundle(Uint8List bytes);
}
