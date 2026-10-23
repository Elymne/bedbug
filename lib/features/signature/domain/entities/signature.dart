import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Icône texte d'une signature dont l'auteur n'en a pas encore choisi.
const String defaultSignatureAvatarText = '(◕‿◕)';

/// Vitesse minimale de l'effet ghost (multiplicateur de la vitesse normale).
///
/// Strictement positive : une vitesse nulle figerait l'animation sur une
/// durée infinie.
const double minGhostSpeed = 0.25;

/// Vitesse maximale de l'effet ghost (multiplicateur de la vitesse normale).
///
/// Au-delà, le tremblement devient un scintillement pénible à regarder.
const double maxGhostSpeed = 5;

/// Vitesse de l'effet ghost d'une signature dont l'auteur ne l'a pas réglée.
const double defaultGhostSpeed = 1;

/// Signature apposée sur un contenu : un pseudo, une icône texte animée d'un effet ghost, et des réseaux.
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
  /// - [socialLinks] : identifiant de l'auteur sur chaque réseau renseigné.
  Signature({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.pseudo,
    this.avatarText = defaultSignatureAvatarText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
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

  /// Identifiant de l'auteur sur chaque réseau renseigné, au plus un par réseau.
  final Map<SocialNetwork, String> socialLinks;
}
