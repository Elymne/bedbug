import 'package:bedbug/features/content/domain/entities/reaction.dart';

/// Règles de forme de la bulle de texte d'une [Reaction].
///
/// Centralisées dans le domaine parce qu'elles valent partout : à la saisie
/// (formulaire), à l'enregistrement (use case), et plus tard à la réception
/// d'une réaction d'un pair, qui ne passe par aucun formulaire.
extension ReactionTextExtension on String {
  /// Indique si ce texte est une bulle valide : une seule ligne, au plus [maxReactionBubbleLength] caractères.
  ///
  /// La longueur est comptée en caractères Unicode (runes) et non en unités
  /// UTF-16, pour qu'un emoji ne compte pas double.
  bool get isValidReactionBubble {
    return runes.length <= maxReactionBubbleLength && !contains('\n');
  }
}
