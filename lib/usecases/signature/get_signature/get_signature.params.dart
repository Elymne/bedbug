import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.usecase.dart';

/// Paramètres du [GetSignatureUsecase].
class GetSignatureParams extends Params {
  /// Crée des [GetSignatureParams].
  ///
  /// - [signatureId] : identifiant de la signature portée par le contenu.
  const GetSignatureParams({required this.signatureId});

  /// Identifiant de la signature portée par le contenu.
  final String signatureId;
}
