import 'package:bedbug/usecases/exchange/select_from_exchange_offer/select_from_exchange_offer.usecase.dart';

/// Échecs possibles du [SelectFromExchangeOfferUsecase].
enum SelectFromExchangeOfferFailure {
  /// L'offre reçue est mal formée ou d'une version inconnue.
  invalidOffer,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la sélection.
  unknown,
}
