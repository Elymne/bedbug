import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';

/// Contenu dessiné dans l'app, au pinceau, sur quelques calques.
///
/// Le dessin voyage sous forme de traits et de remplissages, jamais d'image :
/// il reste léger, et le téléphone qui le reçoit n'a aucun fichier image à
/// décoder, seulement des données dont il vérifie chaque limite.
class DrawingContent extends Content {
  /// Crée un [DrawingContent].
  ///
  /// - [drawing] : dessin du contenu.
  /// - [title] : titre accompagnant le dessin.
  DrawingContent({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.signatureId,
    required super.origin,
    required super.broadcastScore,
    required super.survivalScore,
    required super.displayScore,
    required super.bounce,
    required super.sizeInBytes,
    required super.flair,
    super.tags,
    required this.drawing,
    required this.title,
  });

  /// Dessin du contenu.
  final Drawing drawing;

  /// Titre accompagnant le dessin.
  final String title;

  /// Recrée ce [DrawingContent] avec ses scores mis à jour, pour permettre au
  /// use case de recalcul de persister la nouvelle valeur sans connaître le
  /// détail des champs propres à ce sous-type.
  @override
  DrawingContent copyWithScores({double? broadcastScore, double? survivalScore, double? displayScore}) {
    return DrawingContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      signatureId: signatureId,
      origin: origin,
      broadcastScore: broadcastScore ?? this.broadcastScore,
      survivalScore: survivalScore ?? this.survivalScore,
      displayScore: displayScore ?? this.displayScore,
      bounce: bounce,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      drawing: drawing,
      title: title,
    );
  }

  /// Recrée ce [DrawingContent] avec un [sizeInBytes] mis à jour, pour
  /// permettre au use case de sauvegarde de persister le poids réel sans
  /// connaître le détail des champs propres à ce sous-type.
  @override
  DrawingContent copyWithSizeInBytes(int sizeInBytes) {
    return DrawingContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      signatureId: signatureId,
      origin: origin,
      broadcastScore: broadcastScore,
      survivalScore: survivalScore,
      displayScore: displayScore,
      bounce: bounce,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      drawing: drawing,
      title: title,
    );
  }

  /// Recrée ce [DrawingContent] avec les champs fixés à la réception, pour permettre au use case d'import de les
  /// appliquer sans connaître le détail des champs propres à ce sous-type.
  @override
  DrawingContent copyWithReception({
    required String signatureId,
    required int bounce,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String flair,
  }) {
    return DrawingContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      signatureId: signatureId,
      origin: origin,
      broadcastScore: broadcastScore,
      survivalScore: survivalScore,
      displayScore: displayScore,
      bounce: bounce,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      drawing: drawing,
      title: title,
    );
  }
}
