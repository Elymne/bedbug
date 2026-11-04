import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/usecases/reaction/get_content_reactions/get_content_reactions.failure.dart';
import 'package:bedbug/usecases/reaction/get_content_reactions/get_content_reactions.params.dart';
import 'package:bedbug/usecases/reaction/get_content_reactions/get_content_reactions.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentReactionsSectionNotifier], un par identifiant de contenu.
final contentReactionsSectionNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ContentReactionsSectionNotifier, ContentReactionsSectionState, String>(ContentReactionsSectionNotifier.new);

/// Notifier chargeant les réactions affichées sur la page de détail d'un contenu.
class ContentReactionsSectionNotifier extends AsyncNotifier<ContentReactionsSectionState> {
  /// Crée un [ContentReactionsSectionNotifier].
  ///
  /// - [contentId] : identifiant du contenu affiché.
  ContentReactionsSectionNotifier(this.contentId);

  /// Identifiant du contenu affiché.
  final String contentId;

  /// Cas d'usage de lecture des réactions d'un contenu.
  late final _getContentReactionsUsecase = ref.read(getContentReactionsUsecaseProvider);

  @override
  Future<ContentReactionsSectionState> build() async {
    final result = await _getContentReactionsUsecase(GetContentReactionsParams(contentId: contentId));
    return result.fold(
      onFailure: (GetContentReactionsFailure failure) {
        final message = switch (failure) {
          GetContentReactionsFailure.invalidData => ref.l10n.contentReactionsLoadError,
          GetContentReactionsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetContentReactionsFailure.unknown => ref.l10n.contentReactionsLoadError,
        };
        return ContentReactionsSectionState(reactions: const [], failureMessage: message);
      },
      onSuccess: (List<Reaction> reactions) {
        return ContentReactionsSectionState(reactions: reactions);
      },
    );
  }
}

/// État des réactions d'un contenu.
class ContentReactionsSectionState {
  /// Crée un [ContentReactionsSectionState].
  ///
  /// - [reactions] : réactions du contenu, dans un ordre aléatoire.
  /// - [failureMessage] : message d'erreur si les réactions n'ont pas pu être chargées.
  const ContentReactionsSectionState({required this.reactions, this.failureMessage});

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
