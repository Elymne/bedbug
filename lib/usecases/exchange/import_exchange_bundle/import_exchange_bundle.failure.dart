import 'package:bedbug/usecases/exchange/import_exchange_bundle/import_exchange_bundle.usecase.dart';

/// Échecs possibles du [ImportExchangeBundleUsecase].
enum ImportExchangeBundleFailure {
  /// Le lot ou la demande est mal formé, d'une version inconnue ou trop volumineux.
  invalidBundle,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'import.
  unknown,
}
