import 'dart:typed_data';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/exchange/select_from_exchange_offer/select_from_exchange_offer.usecase.dart';

/// Paramètres du [SelectFromExchangeOfferUsecase].
class SelectFromExchangeOfferParams extends Params {
  /// Crée des [SelectFromExchangeOfferParams].
  ///
  /// - [offerBytes] : offre reçue du pair, encodée.
  /// - [maxContents] : nombre maximal de contenus à demander.
  /// - [maxBytes] : poids cumulé maximal des contenus demandés, en octets.
  const SelectFromExchangeOfferParams({
    required this.offerBytes,
    this.maxContents = defaultMaxRequestedContents,
    this.maxBytes = defaultMaxRequestedBytes,
  });

  /// Offre reçue du pair, encodée.
  final Uint8List offerBytes;

  /// Nombre maximal de contenus à demander.
  final int maxContents;

  /// Poids cumulé maximal des contenus demandés, en octets, avant compression.
  final int maxBytes;
}
