import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';
import 'package:hive_ce/hive.dart';

part 'reaction.model.hive.g.dart';

/// DTO Hive représentant une [Reaction] persistée localement.
@HiveType(typeId: HiveTypeIds.reaction)
class ReactionHiveModel extends HiveObject {
  /// Crée un [ReactionHiveModel].
  ReactionHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.contentId,
    required this.authorId,
    required this.avatarFrames,
    this.bubbleText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
    this.avatarFrameSpeed = defaultAvatarFrameSpeed,
    this.bubbleFont = 0,
  });

  /// Crée un [ReactionHiveModel] depuis une entité [Reaction].
  factory ReactionHiveModel.fromEntity(Reaction entity) {
    return ReactionHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      contentId: entity.contentId,
      authorId: entity.authorId,
      avatarFrames: entity.avatarFrames,
      bubbleText: entity.bubbleText,
      colorArgb: entity.colorArgb,
      ghostSpeed: entity.ghostSpeed,
      avatarFrameSpeed: entity.avatarFrameSpeed,
      bubbleFont: entity.bubbleFont.value,
    );
  }

  /// Identifiant unique de la réaction.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Identifiant du contenu auquel la réaction est rattachée.
  @HiveField(3)
  final String contentId;

  /// Identifiant de la signature qui a réagi.
  @HiveField(4)
  final String authorId;

  // Champ 5 : anciennement le bedbug d'une seule frame, remplacé par
  // [avatarFrames]. Ne pas réutiliser.

  /// Frames du bedbug choisi.
  ///
  /// Les réactions persistées sans ce champ sont relues avec le bedbug par
  /// défaut.
  @HiveField(10, defaultValue: defaultSignatureAvatarFrames)
  final List<String> avatarFrames;

  /// Bulle de texte, `null` pour les réactions stockées avant qu'elle soit obligatoire.
  @HiveField(6)
  final String? bubbleText;

  /// Couleur de l'effet ghost du bedbug en ARGB 32 bits, `null` pour la couleur par défaut.
  @HiveField(7)
  final int? colorArgb;

  /// Intensité de l'effet ghost du bedbug.
  ///
  /// Les réactions persistées avant l'ajout de ce réglage n'ont pas ce
  /// champ : elles sont relues avec l'intensité par défaut.
  @HiveField(8, defaultValue: defaultGhostSpeed)
  final double ghostSpeed;

  /// Vitesse de l'animation du bedbug (multiplicateur de la vitesse normale).
  ///
  /// Les données persistées sans ce champ sont relues avec la vitesse par
  /// défaut.
  @HiveField(11, defaultValue: defaultAvatarFrameSpeed)
  final double avatarFrameSpeed;

  /// Police de la bulle de texte, sous forme de valeur de [TextFont].
  ///
  /// Les réactions persistées avant l'ajout de ce réglage n'ont pas ce
  /// champ : elles sont relues dans la police par défaut.
  @HiveField(9, defaultValue: 0)
  final int bubbleFont;

  /// Convertit ce modèle en entité [Reaction].
  Reaction toEntity() {
    try {
      return Reaction(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        contentId: contentId,
        authorId: authorId,
        avatarFrames: avatarFrames,
        // Les réactions stockées avant que la bulle soit obligatoire n'en ont pas.
        bubbleText: bubbleText ?? '',
        colorArgb: colorArgb,
        // Bornée à la relecture : une valeur hors bornes figerait ou ferait
        // planter l'animation.
        ghostSpeed: ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
        avatarFrameSpeed: avatarFrameSpeed.clamp(minAvatarFrameSpeed, maxAvatarFrameSpeed),
        bubbleFont: TextFont.fromValue(bubbleFont),
      );
    } catch (error) {
      throw DataException('ReactionHiveModel', error);
    }
  }
}
