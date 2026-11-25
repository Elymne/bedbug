import 'package:bedbug/logic/usecases/exchange/save_exchange_log/save_exchange_log.usecase.dart';

/// Échecs possibles du [SaveExchangeLogUsecase].
enum SaveExchangeLogFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}
