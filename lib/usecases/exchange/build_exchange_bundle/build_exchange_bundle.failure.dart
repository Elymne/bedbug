import 'package:bedbug/usecases/exchange/build_exchange_bundle/build_exchange_bundle.usecase.dart';

/// Échecs possibles du [BuildExchangeBundleUsecase].
enum BuildExchangeBundleFailure {
  /// La demande reçue est mal formée ou d'une version inconnue.
  invalidRequest,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la construction du lot.
  unknown,
}
