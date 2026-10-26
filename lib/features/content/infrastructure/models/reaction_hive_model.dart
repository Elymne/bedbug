import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'reaction_hive_model.g.dart';

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
    required this.avatarText,
    this.bubbleText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
  });

  /// Crée un [ReactionHiveModel] depuis une entité [Reaction].
  factory ReactionHiveModel.fromEntity(Reaction entity) {
    return ReactionHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      contentId: entity.contentId,
      authorId: entity.authorId,
      avatarText: entity.avatarText,
      bubbleText: entity.bubbleText,
      colorArgb: entity.colorArgb,
      ghostSpeed: entity.ghostSpeed,
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

  /// Bedbug choisi, sous forme de texte.
  @HiveField(5)
  final String avatarText;

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

  /// Convertit ce modèle en entité [Reaction].
  Reaction toEntity() {
    try {
      return Reaction(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        contentId: contentId,
        authorId: authorId,
        avatarText: avatarText,
        // Les réactions stockées avant que la bulle soit obligatoire n'en ont pas.
        bubbleText: bubbleText ?? '',
        colorArgb: colorArgb,
        // Bornée à la relecture : une valeur hors bornes figerait ou ferait
        // planter l'animation.
        ghostSpeed: ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
      );
    } catch (error) {
      throw DataException('ReactionHiveModel', error);
    }
  }
}
