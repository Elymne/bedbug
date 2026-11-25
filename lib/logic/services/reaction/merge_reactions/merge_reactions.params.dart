import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.service.dart';

/// Paramètres du [MergeReactionsService].
class MergeReactionsParams extends Params {
  /// Crée des [MergeReactionsParams].
  ///
  /// - [reactions] : réactions à intégrer, avant normalisation, dans l'ordre où elles doivent l'être.
  const MergeReactionsParams({required this.reactions});

  /// Réactions à intégrer, avant normalisation, dans l'ordre où elles doivent l'être.
  final List<Reaction> reactions;
}
