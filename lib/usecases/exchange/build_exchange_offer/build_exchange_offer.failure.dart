import 'package:bedbug/usecases/exchange/build_exchange_offer/build_exchange_offer.usecase.dart';

/// Échecs possibles du [BuildExchangeOfferUsecase].
enum BuildExchangeOfferFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la construction de l'offre.
  unknown,
}
