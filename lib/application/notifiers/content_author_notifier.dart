import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/usecases/get_signature_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentAuthorNotifier], un par identifiant d'auteur.
final contentAuthorNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ContentAuthorNotifier, Signature, String>(ContentAuthorNotifier.new);

/// Notifier chargeant le profil de l'auteur affiché sur la page de détail d'un contenu.
class ContentAuthorNotifier extends AsyncNotifier<Signature> {
  /// Crée un [ContentAuthorNotifier].
  ///
  /// - [authorId] : identifiant d'auteur porté par le contenu affiché.
  ContentAuthorNotifier(this.authorId);

  /// Identifiant d'auteur porté par le contenu affiché.
  final String authorId;

  /// Cas d'usage de résolution de l'auteur d'un contenu.
  late final _getAuthorUsecase = ref.read(getSignatureUsecaseProvider);

  @override
  Future<Signature> build() async {
    final result = await _getAuthorUsecase(GetSignatureParams(authorId: authorId));
    return result.fold(
      // Un auteur illisible n'empêche pas de lire le contenu : on le
      // présente comme anonyme plutôt que d'afficher une erreur.
      onFailure: (GetSignatureFailure failure) => anonymousSignature,
      onSuccess: (Signature signature) => signature,
    );
  }
}
