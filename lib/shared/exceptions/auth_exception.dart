/// Codes d'erreur pour les opérations d'authentification.
enum AuthExceptionCode {
  /// Identifiants incorrects (email ou mot de passe invalide).
  invalidCredentials,

  /// L'adresse email est déjà utilisée par un autre compte.
  emailAlreadyInUse,

  /// Le mot de passe ne respecte pas les exigences de sécurité.
  weakPassword,

  /// L'opération nécessite une ré-authentification récente.
  requiresRecentLogin,

  /// Erreur inattendue.
  unknown,
}

/// Exception de domaine pour les erreurs d'authentification.
///
/// Levée par les repositories et attrapée par les use cases pour
/// isoler le domaine des librairies externes (Firebase, etc.).
class AuthException implements Exception {
  /// Crée une [AuthException] avec le [code] d'erreur fourni.
  AuthException(this.code);

  /// Code identifiant la nature de l'erreur.
  final AuthExceptionCode code;
}
