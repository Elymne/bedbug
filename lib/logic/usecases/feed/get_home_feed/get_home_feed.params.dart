import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.usecase.dart';

/// Paramètres du [GetHomeFeedUsecase].
class GetHomeFeedParams extends Params {
  /// Crée des [GetHomeFeedParams].
  ///
  /// - [feedStartedAt] : début de la session de lecture, le même pour toutes les pages d'une session.
  /// - [after] : curseur renvoyé par la page précédente, `null` pour la première page.
  const GetHomeFeedParams({required this.feedStartedAt, this.after});

  /// Début de la session de lecture, le même pour toutes les pages d'une session.
  ///
  /// Le fil est figé à cet instant : un contenu reçu ou vu ensuite ne change rien aux pages suivantes, qui ne
  /// peuvent donc ni répéter ni sauter un contenu.
  final DateTime feedStartedAt;

  /// Curseur renvoyé par la page précédente, `null` pour la première page.
  final String? after;
}
