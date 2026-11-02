import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/services/reaction/merge_reaction/merge_reaction.service.dart';

/// Paramètres du [MergeReactionService].
class MergeReactionParams extends Params {
  /// Crée des [MergeReactionParams].
  ///
  /// - [reaction] : réaction à intégrer, avant normalisation.
  const MergeReactionParams({required this.reaction});

  /// Réaction à intégrer, avant normalisation.
  final Reaction reaction;
}
