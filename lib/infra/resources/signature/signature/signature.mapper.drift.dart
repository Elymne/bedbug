import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/infra/resources/signature/signature/text_font.enum.dart';
import 'package:drift/drift.dart';

/// Conversion entre une [Signature] et sa ligne de la table `signatures`.
///
/// Séparée du repository parce que d'autres repositories lisent aussi des signatures par jointure (un contenu avec la
/// signature de son auteur) : la conversion est écrite une seule fois.
abstract final class SignatureDriftMapper {
  /// Reconstruit la signature d'une ligne.
  ///
  /// Les vitesses sont bornées à la relecture : une valeur stockée hors bornes figerait ou ferait planter l'animation.
  /// Un réseau social inconnu (retiré depuis) est ignoré.
  ///
  /// [row] : ligne lue dans la table `signatures`.
  static Signature toEntity(SignatureRow row) {
    try {
      return Signature(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        pseudo: row.pseudo,
        avatarFrames: row.avatarFrames,
        colorArgb: row.colorArgb,
        ghostSpeed: row.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
        avatarFrameSpeed: row.avatarFrameSpeed.clamp(minAvatarFrameSpeed, maxAvatarFrameSpeed),
        socialLinks: {for (final entry in row.socialLinks.entries) ?SocialNetwork.fromValue(entry.key): entry.value},
        bio: row.bio,
        bioFont: TextFont.fromValue(row.bioFont),
      );
    } catch (error) {
      throw DataException('SignatureDriftMapper', error);
    }
  }

  /// Construit la ligne à écrire pour une signature.
  ///
  /// [entity] : signature à écrire.
  /// [id] : identifiant de la ligne, quand il diffère de celui de l'entité (la signature locale est toujours écrite
  /// sous `localSignatureId`).
  static SignaturesCompanion toCompanion(Signature entity, {String? id}) {
    return SignaturesCompanion.insert(
      id: id ?? entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      pseudo: entity.pseudo,
      avatarFrames: entity.avatarFrames,
      colorArgb: Value(entity.colorArgb),
      ghostSpeed: entity.ghostSpeed,
      avatarFrameSpeed: entity.avatarFrameSpeed,
      socialLinks: {for (final entry in entity.socialLinks.entries) entry.key.value: entry.value},
      bio: Value(entity.bio),
      bioFont: entity.bioFont.value,
    );
  }
}
