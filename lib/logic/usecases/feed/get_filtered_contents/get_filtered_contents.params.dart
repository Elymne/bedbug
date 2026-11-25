import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.usecase.dart';

/// Paramètres du [GetFilteredContentsUsecase].
class GetFilteredContentsParams extends Params {
  /// Crée des [GetFilteredContentsParams].
  ///
  /// - [query] : texte saisi par l'utilisateur, comparé au titre et au flair des contenus.
  /// - [after] : curseur renvoyé par la page précédente, `null` pour la première page.
  const GetFilteredContentsParams({required this.query, this.after});

  /// Texte saisi par l'utilisateur, comparé au titre et au flair des contenus.
  final String query;

  /// Curseur renvoyé par la page précédente, `null` pour la première page.
  final String? after;
}
