import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/content.entity.dart';
import 'package:bedbug/usecases/content/save_content/save_content.usecase.dart';

/// Paramètres du [SaveContentUsecase].
class SaveContentParams extends Params {
  /// Crée des [SaveContentParams].
  ///
  /// - [content] : entité à persister.
  const SaveContentParams({required this.content});

  /// Contenu à persister.
  final Content content;
}
