import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.usecase.dart';

/// Paramètres du [CountContentReactionsUsecase].
class CountContentReactionsParams extends Params {
  /// Crée des [CountContentReactionsParams].
  ///
  /// - [contentId] : identifiant du contenu dont on compte les réactions.
  const CountContentReactionsParams({required this.contentId});

  /// Identifiant du contenu dont on compte les réactions.
  final String contentId;
}
