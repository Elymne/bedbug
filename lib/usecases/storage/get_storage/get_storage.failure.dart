import 'package:bedbug/usecases/storage/get_storage/get_storage.usecase.dart';

/// Échecs possibles du [GetStorageUsecase].
enum GetStorageFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
