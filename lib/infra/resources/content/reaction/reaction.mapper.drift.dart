import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/infra/resources/signature/signature/text_font.enum.dart';
import 'package:drift/drift.dart';

/// Conversion entre une [Reaction] et sa ligne de la table `reactions`.
abstract final class ReactionDriftMapper {
  /// Reconstruit la réaction d'une ligne.
  ///
  /// Les vitesses sont bornées à la relecture : une valeur stockée hors bornes figerait ou ferait planter l'animation.
  /// Une bulle absente (réaction stockée avant que la bulle soit obligatoire) est relue vide.
  ///
  /// [row] : ligne lue dans la table `reactions`.
  static Reaction toEntity(ReactionRow row) {
    try {
      return Reaction(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        contentId: row.contentId,
        authorId: row.authorId,
        avatarFrames: row.avatarFrames,
        bubbleText: row.bubbleText ?? '',
        colorArgb: row.colorArgb,
        ghostSpeed: row.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
        avatarFrameSpeed: row.avatarFrameSpeed.clamp(minAvatarFrameSpeed, maxAvatarFrameSpeed),
        bubbleFont: TextFont.fromValue(row.bubbleFont),
      );
    } catch (error) {
      throw DataException('ReactionDriftMapper', error);
    }
  }

  /// Construit la ligne à écrire pour une réaction.
  ///
  /// [entity] : réaction à écrire.
  static ReactionsCompanion toCompanion(Reaction entity) {
    return ReactionsCompanion.insert(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      contentId: entity.contentId,
      authorId: entity.authorId,
      avatarFrames: entity.avatarFrames,
      bubbleText: Value(entity.bubbleText),
      colorArgb: Value(entity.colorArgb),
      ghostSpeed: entity.ghostSpeed,
      avatarFrameSpeed: entity.avatarFrameSpeed,
      bubbleFont: entity.bubbleFont.value,
    );
  }
}
