import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/content_comments_notifier.dart';
import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/usecases/save_comment_usecase.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveCommentNotifier].
final saveCommentNotifierProvider = AsyncNotifierProvider.autoDispose<SaveCommentNotifier, void>(
  SaveCommentNotifier.new,
);

/// Notifier gérant l'enregistrement d'un commentaire de l'utilisateur sur un contenu.
///
/// Séparé de [ContentCommentsNotifier] : l'enregistrement ne doit pas faire
/// repasser la liste des commentaires en chargement. Son état ne porte que le
/// chargement en cours (pour désactiver le bouton) ; le résultat est retourné
/// directement à l'appelant, seul à savoir quoi afficher.
class SaveCommentNotifier extends AsyncNotifier<void> {
  /// Cas d'usage d'enregistrement d'un commentaire.
  late final _saveCommentUsecase = ref.read(saveCommentUsecaseProvider);

  @override
  Future<void> build() async {}

  /// Enregistre un commentaire de l'utilisateur sur [contentId] et retourne `null` en cas de succès, ou le message d'erreur à afficher.
  ///
  /// Le commentaire est signé par la signature de l'utilisateur du téléphone,
  /// affichée avec lui (pseudo et bedbug). En cas de succès, les commentaires
  /// du contenu sont rechargés.
  ///
  /// - [contentId] : identifiant du contenu à commenter.
  /// - [body] : corps du commentaire.
  Future<String?> save({required String contentId, required String body}) async {
    state = const AsyncLoading();
    final now = DateTime.now();
    final result = await _saveCommentUsecase(
      SaveCommentParams(
        comment: Comment(
          id: UuidX.generate(),
          createdAt: now,
          updatedAt: now,
          contentId: contentId,
          authorId: localSignatureId,
          body: body,
        ),
      ),
    );
    state = const AsyncData(null);

    return result.fold(
      onFailure: (SaveCommentFailure failure) {
        return switch (failure) {
          SaveCommentFailure.invalidComment => ref.l10n.commentInvalidError,
          SaveCommentFailure.storageError => ref.l10n.homeGetContentsStorageError,
          SaveCommentFailure.unknown => ref.l10n.commentSaveError,
        };
      },
      onSuccess: (_) {
        ref.invalidate(contentCommentsNotifierProvider(contentId));
        return null;
      },
    );
  }
}
