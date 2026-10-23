import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'signature_hive_model.g.dart';

/// DTO Hive représentant un [Signature] persisté localement.
@HiveType(typeId: HiveTypeIds.signature)
class SignatureHiveModel extends HiveObject {
  /// Crée un [SignatureHiveModel].
  ///
  /// - [id] : identifiant unique de l'utilisateur.
  /// - [createdAt] : date de création en millisecondes depuis l'époque.
  /// - [updatedAt] : date de mise à jour en millisecondes depuis l'époque.
  /// - [pseudo] : nom d'affichage de l'utilisateur.
  /// - [avatarText] : icône texte de l'utilisateur.
  /// - [colorArgb] : couleur de l'effet ghost en ARGB 32 bits, `null` pour la couleur par défaut.
  /// - [ghostSpeed] : vitesse de l'effet ghost.
  /// - [socialLinks] : identifiants par réseau, indexés par valeur de [SocialNetwork].
  SignatureHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.pseudo,
    required this.avatarText,
    this.colorArgb,
    required this.ghostSpeed,
    required this.socialLinks,
  });

  /// Crée un [SignatureHiveModel] depuis une entité [Signature].
  factory SignatureHiveModel.fromEntity(Signature entity) {
    return SignatureHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      pseudo: entity.pseudo,
      avatarText: entity.avatarText,
      colorArgb: entity.colorArgb,
      ghostSpeed: entity.ghostSpeed,
      socialLinks: {for (final entry in entity.socialLinks.entries) entry.key.value: entry.value},
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

  /// Icône texte de la signature.
  ///
  /// Les signatures persistées avant l'ajout de l'icône n'ont pas ce champ :
  /// elles sont relues avec l'icône par défaut.
  @HiveField(5, defaultValue: defaultSignatureAvatarText)
  final String avatarText;

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

  /// Identifiants de l'utilisateur par réseau, indexés par valeur de [SocialNetwork].
  @HiveField(7, defaultValue: <int, String>{})
  final Map<int, String> socialLinks;

  /// Convertit ce modèle en entité [Signature].
  Signature toEntity() {
    try {
      return Signature(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        pseudo: pseudo,
        avatarText: avatarText,
        colorArgb: colorArgb,
        // Bornée à la relecture : une valeur stockée hors bornes (ancienne
        // force à 0, donnée corrompue) figerait ou ferait planter l'animation.
        ghostSpeed: ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
        socialLinks: {
          for (final entry in socialLinks.entries)
            if (SocialNetwork.fromValue(entry.key) != null) SocialNetwork.fromValue(entry.key)!: entry.value,
        },
      );
    } catch (error) {
      throw DataException('SignatureHiveModel', error);
    }
  }
}
