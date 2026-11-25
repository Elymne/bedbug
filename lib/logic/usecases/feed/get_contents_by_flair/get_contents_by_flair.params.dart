import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_flair/get_contents_by_flair.usecase.dart';

/// Paramètres du [GetContentsByFlairUsecase].
class GetContentsByFlairParams extends Params {
  /// Crée des [GetContentsByFlairParams].
  ///
  /// - [flair] : flair recherché, avec ou sans `/` initial (normalisé par le use case).
  /// - [after] : curseur renvoyé par la page précédente, `null` pour la première page.
  const GetContentsByFlairParams({required this.flair, this.after});

  /// Flair recherché, avec ou sans `/` initial.
  final String flair;

  /// Curseur renvoyé par la page précédente, `null` pour la première page.
  final String? after;
}
