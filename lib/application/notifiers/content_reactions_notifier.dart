import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/usecases/get_content_reactions_usecase.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentReactionsNotifier], un par identifiant de contenu.
final contentReactionsNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ContentReactionsNotifier, ContentReactionsState, String>(ContentReactionsNotifier.new);

/// Notifier chargeant les réactions affichées sur la page de détail d'un contenu.
class ContentReactionsNotifier extends AsyncNotifier<ContentReactionsState> {
  /// Crée un [ContentReactionsNotifier].
  ///
  /// - [contentId] : identifiant du contenu affiché.
  ContentReactionsNotifier(this.contentId);

  /// Identifiant du contenu affiché.
  final String contentId;

  /// Cas d'usage de lecture des réactions d'un contenu.
  late final _getContentReactionsUsecase = ref.read(getContentReactionsUsecaseProvider);

  @override
  Future<ContentReactionsState> build() async {
    final result = await _getContentReactionsUsecase(GetContentReactionsParams(contentId: contentId));
    return result.fold(
      onFailure: (GetContentReactionsFailure failure) {
        final message = switch (failure) {
          GetContentReactionsFailure.invalidData => ref.l10n.contentReactionsLoadError,
          GetContentReactionsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetContentReactionsFailure.unknown => ref.l10n.contentReactionsLoadError,
        };
        return ContentReactionsState(reactions: const [], failureMessage: message);
      },
      onSuccess: (List<Reaction> reactions) {
        return ContentReactionsState(reactions: reactions);
      },
    );
  }
}

/// État des réactions d'un contenu.
class ContentReactionsState {
  /// Crée un [ContentReactionsState].
  ///
  /// - [reactions] : réactions du contenu, dans un ordre aléatoire.
  /// - [failureMessage] : message d'erreur si les réactions n'ont pas pu être chargées.
  const ContentReactionsState({required this.reactions, this.failureMessage});

  /// Réactions du contenu, dans un ordre aléatoire.
  final List<Reaction> reactions;

  /// Message d'erreur si les réactions n'ont pas pu être chargées. `null` si aucun échec.
  final String? failureMessage;

  /// Réaction laissée par l'utilisateur du téléphone, ou `null` s'il n'a pas encore réagi.
  ///
  /// Une signature n'a qu'une réaction par contenu : la page propose de la
  /// modifier plutôt que d'en ajouter une autre, et préremplit le formulaire.
  Reaction? get ownReaction {
    for (final reaction in reactions) {
      if (reaction.authorId == localSignatureId) {
        return reaction;
      }
    }
    return null;
  }
}
