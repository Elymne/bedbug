import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/reaction/get_content_reactions/get_content_reactions.usecase.dart';

/// Paramètres du [GetContentReactionsUsecase].
class GetContentReactionsParams extends Params {
  /// Crée des [GetContentReactionsParams].
  ///
  /// - [contentId] : identifiant du contenu dont on veut les réactions.
  const GetContentReactionsParams({required this.contentId});

  /// Identifiant du contenu dont on veut les réactions.
  final String contentId;
}
