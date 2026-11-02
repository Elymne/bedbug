import 'dart:math';

/// Extension utilitaire sur [String].
extension StringX on String {
  /// Génère un mot de passe aléatoire sécurisé de [length] caractères.
  ///
  /// Utilise [Random.secure()] (CSPRNG système) pour garantir
  /// l'imprévisibilité des caractères générés.
  static String generatePassword({int length = 64}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyz'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        '0123456789'
        r'!@#$%^&*';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Simplement pour parser des Strings (souvent d'inputfields) représentant des doubles avec , à la place de .
  /// A nourir avec d'autres parsing si d'autres cas de séparateurs de numérateur sont possible.
  /// Cette phrase de veut rien dire.
  double get doubleSanitized {
    return double.parse(replaceAll(',', '.'));
  }
}
