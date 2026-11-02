import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.usecase.dart';

/// Paramètres du [GetContentsBySignaturesUsecase].
class GetContentsBySignaturesParams extends Params {
  /// Crée des [GetContentsBySignaturesParams].
  ///
  /// - [signatureIds] : identifiants des signatures dont on veut les contenus.
  const GetContentsBySignaturesParams({required this.signatureIds});

  /// Identifiants des signatures dont on veut les contenus.
  final List<String> signatureIds;
}
