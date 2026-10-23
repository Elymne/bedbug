import 'package:bedbug/features/signature/domain/extensions/signature_text_extension.dart';
import 'package:flutter/services.dart';

/// Bloque en temps réel toute saisie qui ferait apparaître un mot dans l'icône texte.
///
/// Dès qu'une frappe créerait une suite de lettres (voir `isValidAvatarText`),
/// elle est simplement ignorée : l'utilisateur ne peut pas écrire de mot,
/// plutôt que d'en écrire un puis de se voir refuser l'enregistrement.
class AvatarTextInputFormatter extends TextInputFormatter {
  /// Crée un [AvatarTextInputFormatter].
  const AvatarTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Un champ vide (ou réduit à des espaces) reste autorisé pendant la
    // saisie : c'est le validator `required` qui le signale.
    if (newValue.text.trim().isEmpty || newValue.text.isValidAvatarText) {
      return newValue;
    }
    return oldValue;
  }
}
