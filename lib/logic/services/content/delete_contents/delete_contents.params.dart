import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.service.dart';

/// Paramètres du [DeleteContentsService].
class DeleteContentsParams extends Params {
  /// Crée des [DeleteContentsParams].
  ///
  /// - [contentIds] : identifiants des contenus à supprimer.
  const DeleteContentsParams({required this.contentIds});

  /// Identifiants des contenus à supprimer.
  final List<String> contentIds;
}
