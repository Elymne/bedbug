import 'package:bedbug/usecases/trust/delete_untrusted_contents/delete_untrusted_contents.usecase.dart';

/// Échecs possibles du [DeleteUntrustedContentsUsecase].
enum DeleteUntrustedContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la suppression.
  unknown,
}
