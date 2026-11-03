import 'package:bedbug/usecases/storage/recalculate_storage_usage/recalculate_storage_usage.usecase.dart';

/// Échecs possibles du [RecalculateStorageUsageUsecase].
enum RecalculateStorageUsageFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul du poids de stockage.
  unknown,
}
