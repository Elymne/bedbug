import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.usecase.dart';

/// Échecs possibles du [SaveLocalSignatureUsecase].
enum SaveLocalSignatureFailure {
  /// Le pseudo, l'icône ou la description ne respecte pas les règles de `SignatureTextExtension`.
  invalidProfile,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement du profil.
  unknown,
}
