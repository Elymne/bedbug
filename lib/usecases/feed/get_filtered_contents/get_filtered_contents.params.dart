import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/feed/get_filtered_contents/get_filtered_contents.usecase.dart';

/// Paramètres du [GetFilteredContentsUsecase].
class GetFilteredContentsParams extends Params {
  /// Crée des [GetFilteredContentsParams].
  ///
  /// - [query] : texte saisi par l'utilisateur, comparé au titre et au flair des contenus.
  const GetFilteredContentsParams({required this.query});

  /// Texte saisi par l'utilisateur, comparé au titre et au flair des contenus.
  final String query;
}
