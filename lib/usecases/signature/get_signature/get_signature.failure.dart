import 'package:bedbug/usecases/signature/get_signature/get_signature.usecase.dart';

/// Échecs possibles du [GetSignatureUsecase].
enum GetSignatureFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture du profil.
  unknown,
}
