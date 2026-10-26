import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/usecases/get_content_comments_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentCommentsNotifier], un par identifiant de contenu.
final contentCommentsNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ContentCommentsNotifier, ContentCommentsState, String>(ContentCommentsNotifier.new);

/// Notifier chargeant les commentaires affichés sur la page de détail d'un contenu.
class ContentCommentsNotifier extends AsyncNotifier<ContentCommentsState> {
  /// Crée un [ContentCommentsNotifier].
  ///
  /// - [contentId] : identifiant du contenu affiché.
  ContentCommentsNotifier(this.contentId);

  /// Identifiant du contenu affiché.
  final String contentId;

  /// Cas d'usage de lecture des commentaires d'un contenu.
  late final _getContentCommentsUsecase = ref.read(getContentCommentsUsecaseProvider);

  @override
  Future<ContentCommentsState> build() async {
    final result = await _getContentCommentsUsecase(GetContentCommentsParams(contentId: contentId));
    return result.fold(
      onFailure: (GetContentCommentsFailure failure) {
        final message = switch (failure) {
          GetContentCommentsFailure.invalidData => ref.l10n.contentCommentsLoadError,
          GetContentCommentsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetContentCommentsFailure.unknown => ref.l10n.contentCommentsLoadError,
        };
        return ContentCommentsState(comments: const [], failureMessage: message);
      },
      onSuccess: (List<Comment> comments) {
        return ContentCommentsState(comments: comments);
      },
    );
  }
}

/// État des commentaires d'un contenu.
class ContentCommentsState {
  /// Crée un [ContentCommentsState].
  ///
  /// - [comments] : commentaires du contenu, dans un ordre aléatoire.
  /// - [failureMessage] : message d'erreur si les commentaires n'ont pas pu être chargés.
  const ContentCommentsState({required this.comments, this.failureMessage});

  /// Commentaires du contenu, dans un ordre aléatoire.
  final List<Comment> comments;

  /// Message d'erreur si les commentaires n'ont pas pu être chargés. `null` si aucun échec.
  final String? failureMessage;
}
