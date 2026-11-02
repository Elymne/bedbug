import 'package:bedbug/usecases/storage/save_storage_limit/save_storage_limit.usecase.dart';

/// Échecs possibles du [SaveStorageLimitUsecase].
enum SaveStorageLimitFailure {
  /// La limite demandée sort des bornes autorisées.
  invalidLimit,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}
