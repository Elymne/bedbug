import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.service.dart';

/// Paramètres du [DeleteContentsService].
class DeleteContentsParams extends Params {
  /// Crée des [DeleteContentsParams].
  ///
  /// - [contents] : contenus à supprimer, tels que lus en base (leur poids est retiré du total).
  const DeleteContentsParams({required this.contents});

  /// Contenus à supprimer, tels que lus en base.
  final List<Content> contents;
}
