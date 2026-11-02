import 'package:bedbug/core/domain/entity.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';

/// Signature anonyme, identique pour tout le monde.
///
/// Codée en dur dans l'app et jamais stockée en base : un contenu anonyme ne
/// doit rien révéler de son auteur, pas même une signature qu'il aurait pu
/// modifier. Sert aussi de repli pour tout auteur dont la signature est
/// inconnue de l'appareil.
/// Icône « agent secret », couleur et vitesse du ghost par défaut, aucun
/// réseau.
final Signature anonymousSignature = Signature(
  id: anonymousSignatureId,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  pseudo: 'anonyme',
  avatarText: '(⌐■_■)',
);

/// Signature apposée sur un contenu : un pseudo, une icône texte animée d'un effet ghost, une courte description et des réseaux.
///
/// Ce n'est pas une identité : sans serveur, rien ne la vérifie, et
/// n'importe qui peut signer sous n'importe quel pseudo. Elle sert à donner
/// du style aux auteurs, pas à les authentifier. La notion d'utilisateur
/// (identité, clés) est un sujet à part, prévu pour la V2.
class Signature extends Entity {
  /// Crée une [Signature].
  ///
  /// - [pseudo] : nom affiché sous la forme `s/pseudo`.
  /// - [avatarText] : icône composée de texte (kaomoji, emoji, symboles), sans mot.
  /// - [colorArgb] : couleur de l'effet ghost appliqué à [avatarText], `null` pour la couleur par défaut de l'app.
  /// - [ghostSpeed] : vitesse de l'effet ghost, entre [minGhostSpeed] et [maxGhostSpeed].
  /// - [bio] : courte description de l'auteur, au plus [maxSignatureBioLength] caractères, `null` s'il n'en a pas.
  /// - [bioFont] : police de [bio] (défaut [TextFont.standard]).
  /// - [socialLinks] : identifiant de l'auteur sur chaque réseau renseigné.
  Signature({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.pseudo,
    this.avatarText = defaultSignatureAvatarText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
    this.bio,
    this.bioFont = TextFont.standard,
    this.socialLinks = const {},
  });

  /// Nom affiché sous la forme `s/pseudo`.
  final String pseudo;

  /// Icône de la signature, composée de texte.
  final String avatarText;

  /// Couleur de l'effet ghost appliqué à [avatarText], encodée en ARGB 32 bits (`0xAARRGGBB`).
  ///
  /// La couleur est libre (choisie au color picker) : le domaine la stocke
  /// sous forme d'entier, sans dépendre du type `Color` de Flutter. `null`
  /// signifie que l'utilisateur garde la couleur par défaut de l'app.
  final int? colorArgb;

  /// Vitesse de l'effet ghost appliqué à [avatarText], entre [minGhostSpeed] et [maxGhostSpeed].
  ///
  /// Multiplicateur de la vitesse normale du tremblement (1 = vitesse
  /// normale) : l'amplitude, elle, ne change pas. Présentée à l'utilisateur
  /// comme la « force » de l'effet.
  final double ghostSpeed;

  /// Courte description que l'auteur donne de lui-même, sur une seule ligne. `null` s'il n'en a pas.
  final String? bio;

  /// Police dans laquelle [bio] est affichée, pour donner le ton de la présentation.
  final TextFont bioFont;

  /// Identifiant de l'auteur sur chaque réseau renseigné, au plus un par réseau.
  final Map<SocialNetwork, String> socialLinks;

  /// Lettres latines (accentuées ou pleine chasse comprises), grecques et cyrilliques.
  ///
  /// Ce sont les alphabets avec lesquels on écrit des mots lisibles. Les kaomojis en empruntent parfois une isolée
  /// (`ω`, `Д`, `Σ`, `T_T`), jamais plusieurs à la suite.
  static final RegExp _wordLetterRun = RegExp('[A-Za-zÀ-ÖØ-öø-ÿＡ-Ｚａ-ｚͰ-ϿЀ-ӿ]{2,}');

  /// Suite de lettres tolérée malgré tout : le `zzZ` des kaomojis endormis.
  static final RegExp _sleepLetterRun = RegExp(r'^[zZ]+$');

  /// Indique si [pseudo] est un pseudo valide : lettres non accentuées et tirets, entre [minPseudoLength] et
  /// [maxPseudoLength] caractères.
  ///
  /// Le pseudo est affiché sous la forme `s/pseudo` : espaces, chiffres et symboles le rendraient illisible ou
  /// permettraient d'imiter un autre affichage. La règle vaut aussi pour le profil reçu d'un pair, qui ne passe par
  /// aucun formulaire.
  ///
  /// - [pseudo] : texte à vérifier.
  static bool isValidPseudo(String pseudo) {
    return RegExp('^[A-Za-z-]{$minPseudoLength,$maxPseudoLength}\$').hasMatch(pseudo);
  }

  /// Indique si [avatarText] est une icône valide : non vide et sans mot.
  ///
  /// Une icône est une émote (kaomoji, emoji, symboles) : on refuse toute suite de deux lettres ou plus, pour qu'on ne
  /// puisse pas y écrire de mot. Seul le `zzZ` des émotes endormies fait exception.
  ///
  /// - [avatarText] : texte à vérifier.
  static bool isValidAvatarText(String avatarText) {
    if (avatarText.trim().isEmpty) {
      return false;
    }
    return _wordLetterRun.allMatches(avatarText).every((match) => _sleepLetterRun.hasMatch(match.group(0)!));
  }

  /// Indique si [bio] est une description valide : une seule ligne, au plus [maxSignatureBioLength] caractères.
  ///
  /// La longueur est comptée en caractères Unicode (runes) et non en unités UTF-16, pour qu'un emoji ne compte pas
  /// double.
  ///
  /// - [bio] : texte à vérifier.
  static bool isValidBio(String bio) {
    return bio.runes.length <= maxSignatureBioLength && !bio.contains('\n');
  }
}
