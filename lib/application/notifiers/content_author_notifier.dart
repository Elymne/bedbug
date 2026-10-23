import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/usecases/get_author_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentAuthorNotifier], un par identifiant d'auteur.
final contentAuthorNotifierProvider = AsyncNotifierProvider.autoDispose.family<ContentAuthorNotifier, User, String>(
  ContentAuthorNotifier.new,
);

/// Notifier chargeant le profil de l'auteur affiché sur la page de détail d'un contenu.
class ContentAuthorNotifier extends AsyncNotifier<User> {
  /// Crée un [ContentAuthorNotifier].
  ///
  /// - [authorId] : identifiant d'auteur porté par le contenu affiché.
  ContentAuthorNotifier(this.authorId);

  /// Identifiant d'auteur porté par le contenu affiché.
  final String authorId;

  /// Cas d'usage de résolution de l'auteur d'un contenu.
  late final _getAuthorUsecase = ref.read(getAuthorUsecaseProvider);

  @override
  Future<User> build() async {
    final result = await _getAuthorUsecase(GetAuthorParams(authorId: authorId));
    return result.fold(
      // Un auteur illisible n'empêche pas de lire le contenu : on le
      // présente comme anonyme plutôt que d'afficher une erreur.
      onFailure: (GetAuthorFailure failure) => anonymousUser,
      onSuccess: (User user) => user,
    );
  }
}
