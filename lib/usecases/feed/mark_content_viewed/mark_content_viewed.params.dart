import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/feed/mark_content_viewed/mark_content_viewed.usecase.dart';

/// Paramètres du [MarkContentViewedUsecase].
class MarkContentViewedParams extends Params {
  /// Crée un [MarkContentViewedParams].
  ///
  /// - [contentId] : identifiant du contenu vu.
  const MarkContentViewedParams({required this.contentId});

  /// Identifiant du contenu vu.
  final String contentId;
}
