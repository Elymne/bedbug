import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Ce qu'il faut faire des réactions d'un contenu pour y intégrer une nouvelle réaction.
///
/// Sert aux use cases qui enregistrent une réaction : la décision est la même partout, seule l'écriture leur revient.
class ReactionMerge extends ValueObject {
  /// Crée un [ReactionMerge].
  ///
  /// - [kept] : réaction conservée pour cet auteur.
  /// - [isNewReactionKept] : `false` si une version aussi récente est déjà connue : rien n'est à écrire.
  /// - [replacedIds] : réactions précédentes de cet auteur, à supprimer.
  /// - [overflowIds] : réactions les plus anciennes, à supprimer pour rester sous le plafond.
  const ReactionMerge({
    required this.kept,
    required this.isNewReactionKept,
    required this.replacedIds,
    required this.overflowIds,
  });

  /// Réaction conservée pour cet auteur.
  final Reaction kept;

  /// Vrai si la nouvelle réaction doit être écrite.
  final bool isNewReactionKept;

  /// Réactions précédentes de cet auteur, à supprimer.
  final List<String> replacedIds;

  /// Réactions les plus anciennes, à supprimer pour rester sous le plafond.
  final List<String> overflowIds;

  @override
  bool operator ==(Object other) {
    return other is ReactionMerge &&
        other.kept == kept &&
        other.isNewReactionKept == isNewReactionKept &&
        _isSameList(other.replacedIds, replacedIds) &&
        _isSameList(other.overflowIds, overflowIds);
  }

  @override
  int get hashCode {
    return Object.hash(kept, isNewReactionKept, Object.hashAll(replacedIds), Object.hashAll(overflowIds));
  }

  @override
  String toString() {
    return 'ReactionMerge(${kept.id}, écrite : $isNewReactionKept, ${replacedIds.length} remplacées, '
        '${overflowIds.length} en trop)';
  }

  /// Indique si [left] et [right] contiennent les mêmes identifiants, dans le même ordre.
  ///
  /// - [left] : première liste.
  /// - [right] : seconde liste.
  bool _isSameList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
