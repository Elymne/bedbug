import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';
import 'package:hive_ce/hive.dart';

part 'signature.model.hive.g.dart';

/// DTO Hive représentant un [Signature] persisté localement.
@HiveType(typeId: HiveTypeIds.signature)
class SignatureHiveModel extends HiveObject {
  /// Crée un [SignatureHiveModel].
  ///
  /// - [id] : identifiant unique de l'utilisateur.
  /// - [createdAt] : date de création en millisecondes depuis l'époque.
  /// - [updatedAt] : date de mise à jour en millisecondes depuis l'époque.
  /// - [pseudo] : nom d'affichage de l'utilisateur.
  /// - [avatarFrames] : frames du bedbug de la signature.
  /// - [colorArgb] : couleur de l'effet ghost en ARGB 32 bits, `null` pour la couleur par défaut.
  /// - [ghostSpeed] : vitesse de l'effet ghost.
  /// - [avatarFrameSpeed] : vitesse de l'animation du bedbug.
  /// - [socialLinks] : identifiants par réseau, indexés par valeur de [SocialNetwork].
  /// - [bio] : courte description de l'utilisateur, `null` s'il n'en a pas.
  /// - [bioFont] : police de la description, valeur de [TextFont].
  SignatureHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.pseudo,
    required this.avatarFrames,
    this.colorArgb,
    required this.ghostSpeed,
    this.avatarFrameSpeed = defaultAvatarFrameSpeed,
    required this.socialLinks,
    this.bio,
    this.bioFont = 0,
  });

  /// Crée un [SignatureHiveModel] depuis une entité [Signature].
  factory SignatureHiveModel.fromEntity(Signature entity) {
    return SignatureHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      pseudo: entity.pseudo,
      avatarFrames: entity.avatarFrames,
      colorArgb: entity.colorArgb,
      ghostSpeed: entity.ghostSpeed,
      avatarFrameSpeed: entity.avatarFrameSpeed,
      socialLinks: {for (final entry in entity.socialLinks.entries) entry.key.value: entry.value},
      bio: entity.bio,
      bioFont: entity.bioFont.value,
    );
  }

  /// Identifiant unique de l'utilisateur.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Nom d'affichage de l'utilisateur.
  @HiveField(3)
  final String pseudo;

  // Champ 4 : anciennement l'e-mail de l'utilisateur, retiré parce qu'une
  // signature voyage avec les contenus. Ne pas réutiliser.

  // Champ 5 : anciennement l'icône texte, d'une seule frame, remplacée par
  // [avatarFrames]. Ne pas réutiliser.

  /// Frames du bedbug de la signature.
  ///
  /// Les signatures persistées sans ce champ sont relues avec le bedbug par
  /// défaut.
  @HiveField(12, defaultValue: defaultSignatureAvatarFrames)
  final List<String> avatarFrames;

  /// Couleur de l'effet ghost encodée en ARGB 32 bits, `null` pour la couleur par défaut de l'app.
  ///
  /// Le champ 6 (ancien index de palette fixe) est volontairement laissé
  /// inutilisé : le réutiliser ferait relire un index comme une couleur ARGB.
  @HiveField(8)
  final int? colorArgb;

  /// Vitesse de l'effet ghost (multiplicateur de la vitesse normale).
  ///
  /// Les utilisateurs persistés avant l'ajout de ce réglage n'ont pas ce
  /// champ : ils sont relus avec la vitesse par défaut.
  @HiveField(9, defaultValue: defaultGhostSpeed)
  final double ghostSpeed;

  /// Vitesse de l'animation du bedbug (multiplicateur de la vitesse normale).
  ///
  /// Les données persistées sans ce champ sont relues avec la vitesse par
  /// défaut.
  @HiveField(13, defaultValue: defaultAvatarFrameSpeed)
  final double avatarFrameSpeed;

  /// Identifiants de l'utilisateur par réseau, indexés par valeur de [SocialNetwork].
  @HiveField(7, defaultValue: <int, String>{})
  final Map<int, String> socialLinks;

  /// Courte description de l'utilisateur, `null` s'il n'en a pas.
  ///
  /// Les utilisateurs persistés avant l'ajout de la description n'ont pas ce
  /// champ : ils sont relus sans description.
  @HiveField(10)
  final String? bio;

  /// Police de la description, sous forme de valeur de [TextFont].
  ///
  /// Les utilisateurs persistés avant l'ajout de ce réglage n'ont pas ce
  /// champ : leur description est relue dans la police par défaut.
  @HiveField(11, defaultValue: 0)
  final int bioFont;

  /// Convertit ce modèle en entité [Signature].
  Signature toEntity() {
    try {
      return Signature(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        pseudo: pseudo,
        avatarFrames: avatarFrames,
        colorArgb: colorArgb,
        // Bornée à la relecture : une valeur stockée hors bornes (ancienne
        // force à 0, donnée corrompue) figerait ou ferait planter l'animation.
        ghostSpeed: ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
        avatarFrameSpeed: avatarFrameSpeed.clamp(minAvatarFrameSpeed, maxAvatarFrameSpeed),
        socialLinks: {
          for (final entry in socialLinks.entries)
            if (SocialNetwork.fromValue(entry.key) != null) SocialNetwork.fromValue(entry.key)!: entry.value,
        },
        bio: bio,
        bioFont: TextFont.fromValue(bioFont),
      );
    } catch (error) {
      throw DataException('SignatureHiveModel', error);
    }
  }
}
