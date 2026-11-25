import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.usecase.dart';

/// Paramètres du [GetContentsBySignaturesUsecase].
class GetContentsBySignaturesParams extends Params {
  /// Crée des [GetContentsBySignaturesParams].
  ///
  /// - [signatureIds] : identifiants des signatures dont on veut les contenus.
  /// - [after] : curseur renvoyé par la page précédente, `null` pour la première page.
  const GetContentsBySignaturesParams({required this.signatureIds, this.after});

  /// Identifiants des signatures dont on veut les contenus.
  final List<String> signatureIds;

  /// Curseur renvoyé par la page précédente, `null` pour la première page.
  final String? after;
}
