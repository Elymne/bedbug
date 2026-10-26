import 'package:bedbug/features/content/domain/entities/comment.dart';

/// Règles de forme du corps d'un [Comment].
///
/// Centralisées dans le domaine parce qu'elles valent partout : à la saisie
/// (formulaire), à l'enregistrement (use case), et plus tard à la réception
/// d'un commentaire d'un pair, qui ne passe par aucun formulaire.
extension CommentTextExtension on String {
  /// Indique si ce texte est un corps de commentaire valide : non vide, au plus [maxCommentLength] caractères.
  ///
  /// Les sauts de ligne sont autorisés. La longueur est comptée en caractères
  /// Unicode (runes) et non en unités UTF-16, pour qu'un emoji ne compte pas
  /// double.
  bool get isValidCommentBody {
    return trim().isNotEmpty && runes.length <= maxCommentLength;
  }
}
