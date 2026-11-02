import 'package:bedbug/resources/signature/signature.entity.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.failure.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.params.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentAuthorNotifier], un par identifiant de signature.
final contentAuthorNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ContentAuthorNotifier, Signature, String>(ContentAuthorNotifier.new);

/// Notifier chargeant le profil de l'auteur affiché sur la page de détail d'un contenu.
class ContentAuthorNotifier extends AsyncNotifier<Signature> {
  /// Crée un [ContentAuthorNotifier].
  ///
  /// - [signatureId] : identifiant de la signature à afficher.
  ContentAuthorNotifier(this.signatureId);

  /// Identifiant de la signature à afficher.
  final String signatureId;

  /// Cas d'usage de résolution de l'auteur d'un contenu.
  late final _getSignatureUsecase = ref.read(getSignatureUsecaseProvider);

  @override
  Future<Signature> build() async {
    final result = await _getSignatureUsecase(GetSignatureParams(signatureId: signatureId));
    return result.fold(
      // Un auteur illisible n'empêche pas de lire le contenu : on le
      // présente comme anonyme plutôt que d'afficher une erreur.
      onFailure: (GetSignatureFailure failure) => anonymousSignature,
      onSuccess: (Signature signature) => signature,
    );
  }
}
