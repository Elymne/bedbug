import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/content/delete_own_content/delete_own_content.usecase.dart';

/// Paramètres du [DeleteOwnContentUsecase].
class DeleteOwnContentParams extends Params {
  /// Crée des [DeleteOwnContentParams].
  ///
  /// - [contentId] : identifiant du contenu à supprimer.
  const DeleteOwnContentParams({required this.contentId});

  /// Identifiant du contenu à supprimer.
  final String contentId;
}
