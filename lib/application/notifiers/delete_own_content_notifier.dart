import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/own_contents_notifier.dart';
import 'package:bedbug/application/screens/home/home_feed_notifier.dart';
import 'package:bedbug/features/content/domain/usecases/delete_own_content_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DeleteOwnContentNotifier].
final deleteOwnContentNotifierProvider = AsyncNotifierProvider<DeleteOwnContentNotifier, void>(
  DeleteOwnContentNotifier.new,
);

/// Notifier gérant la suppression d'un contenu publié par l'utilisateur.
///
/// Partagé entre la page de détail et la liste « Mes posts » des options.
/// Son état ne porte que le chargement en cours (pour désactiver les
/// boutons) : le résultat est retourné directement à l'appelant, qui est le
/// seul à savoir quoi afficher (fermer la page de détail, ou rester sur la
/// liste).
class DeleteOwnContentNotifier extends AsyncNotifier<void> {
  /// Cas d'usage de suppression d'un contenu de l'utilisateur.
  late final _deleteOwnContentUsecase = ref.read(deleteOwnContentUsecaseProvider);

  @override
  Future<void> build() async {}

  /// Supprime le contenu [contentId] et retourne `null` en cas de succès, ou le message d'erreur à afficher.
  ///
  /// En cas de succès, la liste « Mes posts » et le fil de la home page sont
  /// rechargés pour ne plus afficher le contenu supprimé.
  ///
  /// - [contentId] : identifiant du contenu à supprimer.
  Future<String?> delete(String contentId) async {
    state = const AsyncLoading();
    final result = await _deleteOwnContentUsecase(DeleteOwnContentParams(contentId: contentId));
    state = const AsyncData(null);

    return result.fold(
      onFailure: (DeleteOwnContentFailure failure) {
        return switch (failure) {
          DeleteOwnContentFailure.notFound => ref.l10n.deleteContentNotFound,
          DeleteOwnContentFailure.notOwned => ref.l10n.deleteContentNotOwned,
          DeleteOwnContentFailure.storageError => ref.l10n.homeGetContentsStorageError,
          DeleteOwnContentFailure.unknown => ref.l10n.deleteContentError,
        };
      },
      onSuccess: (_) {
        ref.invalidate(ownContentsNotifierProvider);
        ref.invalidate(homeFeedNotifierProvider);
        return null;
      },
    );
  }
}
