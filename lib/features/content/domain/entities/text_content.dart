import 'package:bedbug/features/content/domain/entities/content.dart';

/// Contenu de type texte, composé d'un titre et d'un corps.
class TextContent extends Content {
  /// Crée un [TextContent].
  ///
  /// - [title] : titre du contenu.
  /// - [body] : corps du contenu.
  TextContent({
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
    required this.title,
    required this.body,
  });

  /// Titre du contenu.
  final String title;

  /// Corps du contenu.
  final String body;

  /// Recrée ce [TextContent] avec ses scores mis à jour, pour permettre au
  /// use case de recalcul de persister la nouvelle valeur sans connaître le
  /// détail des champs propres à ce sous-type.
  @override
  TextContent copyWithScores({double? broadcastScore, double? survivalScore, double? displayScore}) {
    return TextContent(
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
      title: title,
      body: body,
    );
  }

  /// Recrée ce [TextContent] avec un [sizeInBytes] mis à jour, pour permettre
  /// au use case de sauvegarde de persister le poids réel sans connaître le
  /// détail des champs propres à ce sous-type.
  @override
  TextContent copyWithSizeInBytes(int sizeInBytes) {
    return TextContent(
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
      title: title,
      body: body,
    );
  }

  /// Recrée ce [TextContent] avec les champs fixés à la réception, pour permettre au use case d'import de les
  /// appliquer sans connaître le détail des champs propres à ce sous-type.
  @override
  TextContent copyWithReception({
    required String signatureId,
    required int bounce,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String flair,
  }) {
    return TextContent(
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
      title: title,
      body: body,
    );
  }
}
