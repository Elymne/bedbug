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
    required super.authorId,
    required super.priority,
    required super.bounce,
    required super.senderId,
    super.subId,
    required this.title,
    required this.body,
  });

  /// Titre du contenu.
  final String title;

  /// Corps du contenu.
  final String body;
}
