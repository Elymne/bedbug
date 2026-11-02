import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/reaction.entity.dart';
import 'package:bedbug/usecases/reaction/save_reaction/save_reaction.usecase.dart';

/// Paramètres du [SaveReactionUsecase].
class SaveReactionParams extends Params {
  /// Crée des [SaveReactionParams].
  ///
  /// - [reaction] : réaction à enregistrer, avant normalisation.
  const SaveReactionParams({required this.reaction});

  /// Réaction à enregistrer, avant normalisation.
  final Reaction reaction;
}
