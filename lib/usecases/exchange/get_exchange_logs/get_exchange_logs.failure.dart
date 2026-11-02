import 'package:bedbug/usecases/exchange/get_exchange_logs/get_exchange_logs.usecase.dart';

/// Échecs possibles du [GetExchangeLogsUsecase].
enum GetExchangeLogsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture.
  unknown,
}
