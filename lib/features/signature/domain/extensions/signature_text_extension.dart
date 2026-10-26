import 'package:bedbug/features/signature/domain/entities/signature.dart';

/// Longueur minimale d'un pseudo.
const int minPseudoLength = 3;

/// Longueur maximale d'un pseudo.
const int maxPseudoLength = 24;

/// Caractères autorisés dans un pseudo : lettres non accentuées et tiret.
final RegExp pseudoAllowedCharacter = RegExp('[A-Za-z-]');

/// Lettres latines (accentuées ou pleine chasse comprises), grecques et cyrilliques.
///
/// Ce sont les alphabets avec lesquels on écrit des mots lisibles. Les
/// kaomojis en empruntent parfois une isolée (`ω`, `Д`, `Σ`, `T_T`), jamais
/// plusieurs à la suite.
final RegExp _wordLetterRun = RegExp('[A-Za-zÀ-ÖØ-öø-ÿＡ-Ｚａ-ｚͰ-ϿЀ-ӿ]{2,}');

/// Suite de lettres tolérée malgré tout : le `zzZ` des kaomojis endormis.
final RegExp _sleepLetterRun = RegExp(r'^[zZ]+$');

/// Règles de forme du pseudo, de l'icône texte et de la description d'un profil.
///
/// Centralisées dans le domaine parce qu'elles valent partout : à la saisie
/// (formulaire), à l'enregistrement (use case), et plus tard à la réception
/// du profil d'un pair, qui ne passe par aucun formulaire.
extension SignatureTextExtension on String {
  /// Indique si ce texte est un pseudo valide : lettres non accentuées et tirets, entre [minPseudoLength] et [maxPseudoLength] caractères.
  ///
  /// Le pseudo est affiché sous la forme `s/pseudo` : espaces, chiffres et
  /// symboles le rendraient illisible ou permettraient d'imiter un autre
  /// affichage.
  bool get isValidPseudo {
    return RegExp('^[A-Za-z-]{$minPseudoLength,$maxPseudoLength}\$').hasMatch(this);
  }

  /// Indique si ce texte est une icône valide : non vide et sans mot.
  ///
  /// Une icône est une émote (kaomoji, emoji, symboles) : on refuse toute
  /// suite de deux lettres ou plus, pour qu'on ne puisse pas y écrire de mot.
  /// Seul le `zzZ` des émotes endormies fait exception.
  bool get isValidAvatarText {
    if (trim().isEmpty) {
      return false;
    }
    return _wordLetterRun.allMatches(this).every((match) => _sleepLetterRun.hasMatch(match.group(0)!));
  }

  /// Indique si ce texte est une description valide : une seule ligne, au plus [maxSignatureBioLength] caractères.
  ///
  /// La longueur est comptée en caractères Unicode (runes) et non en unités
  /// UTF-16, pour qu'un emoji ne compte pas double.
  bool get isValidSignatureBio {
    return runes.length <= maxSignatureBioLength && !contains('\n');
  }
}
