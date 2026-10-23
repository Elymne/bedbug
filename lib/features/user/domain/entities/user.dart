import 'package:bedbug/features/user/domain/enums/social_network.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Icône texte attribuée à un utilisateur qui n'en a pas encore choisi.
const String defaultUserAvatarText = '(◕‿◕)';

/// Vitesse minimale de l'effet ghost (multiplicateur de la vitesse normale).
///
/// Strictement positive : une vitesse nulle figerait l'animation sur une
/// durée infinie.
const double minGhostSpeed = 0.25;

/// Vitesse maximale de l'effet ghost (multiplicateur de la vitesse normale).
///
/// Au-delà, le tremblement devient un scintillement pénible à regarder.
const double maxGhostSpeed = 5;

/// Vitesse de l'effet ghost attribuée à un utilisateur qui ne l'a pas réglée.
const double defaultGhostSpeed = 1;

/// Représente un utilisateur de l'application.
///
/// Sans serveur, rien de tout cela n'est vérifiable : un pair peut se
/// présenter sous n'importe quel pseudo. Le profil sert à donner du style aux
/// auteurs, pas à les authentifier.
class User extends Entity {
  /// Crée un [User].
  ///
  /// - [pseudo] : nom d'affichage choisi par l'utilisateur.
  /// - [email] : adresse e-mail, nullable car non obligatoire.
  /// - [avatarText] : icône de l'utilisateur, composée de texte (kaomoji, emoji, initiales…).
  /// - [colorArgb] : couleur de l'effet ghost appliqué à [avatarText], `null` pour la couleur par défaut de l'app.
  /// - [ghostSpeed] : vitesse de l'effet ghost, entre [minGhostSpeed] et [maxGhostSpeed].
  /// - [socialLinks] : identifiant de l'utilisateur sur chaque réseau renseigné.
  User({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.pseudo,
    this.email,
    this.avatarText = defaultUserAvatarText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
    this.socialLinks = const {},
  });

  /// Nom d'affichage de l'utilisateur.
  final String pseudo;

  /// Adresse e-mail de l'utilisateur, nullable.
  final String? email;

  /// Icône de l'utilisateur, composée de texte.
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

  /// Identifiant de l'utilisateur sur chaque réseau renseigné, au plus un par réseau.
  final Map<SocialNetwork, String> socialLinks;
}
