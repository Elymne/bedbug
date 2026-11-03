import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.usecase.dart';

/// Échecs possibles du [GetLocalSignatureUsecase].
enum GetLocalSignatureFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture du profil.
  unknown,
}
