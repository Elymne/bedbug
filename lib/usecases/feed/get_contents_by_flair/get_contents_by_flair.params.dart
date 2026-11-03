import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/feed/get_contents_by_flair/get_contents_by_flair.usecase.dart';

/// Paramètres du [GetContentsByFlairUsecase].
class GetContentsByFlairParams extends Params {
  /// Crée des [GetContentsByFlairParams].
  ///
  /// - [flair] : flair recherché, avec ou sans `/` initial (normalisé par le use case).
  const GetContentsByFlairParams({required this.flair});

  /// Flair recherché, avec ou sans `/` initial.
  final String flair;
}
