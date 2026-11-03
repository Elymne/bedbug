import 'package:bedbug/usecases/storage/enforce_storage_limit/enforce_storage_limit.usecase.dart';

/// Échecs possibles du [EnforceStorageLimitUsecase].
enum EnforceStorageLimitFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du nettoyage.
  unknown,
}
