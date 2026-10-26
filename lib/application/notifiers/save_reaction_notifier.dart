import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/content_reaction_count_notifier.dart';
import 'package:bedbug/application/notifiers/content_reactions_notifier.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/usecases/save_reaction_usecase.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveReactionNotifier].
final saveReactionNotifierProvider = AsyncNotifierProvider.autoDispose<SaveReactionNotifier, void>(
  SaveReactionNotifier.new,
);

/// Notifier gérant l'enregistrement de la réaction de l'utilisateur sur un contenu.
///
/// Séparé de [ContentReactionsNotifier] : l'enregistrement ne doit pas faire
/// repasser la liste des réactions en chargement. Son état ne porte que le
/// chargement en cours (pour désactiver le bouton) ; le résultat est retourné
/// directement à l'appelant, seul à savoir quoi afficher.
class SaveReactionNotifier extends AsyncNotifier<void> {
  /// Cas d'usage d'enregistrement d'une réaction.
  late final _saveReactionUsecase = ref.read(saveReactionUsecaseProvider);

  @override
  Future<void> build() async {}

  /// Enregistre la réaction de l'utilisateur sur [contentId] et retourne `null` en cas de succès, ou le message d'erreur à afficher.
  ///
  /// La réaction est signée par l'utilisateur du téléphone, jamais en
  /// anonyme : toutes les réactions anonymes partageraient le même auteur et
  /// se remplaceraient entre elles. Elle remplace la précédente réaction de
  /// l'utilisateur, dont la date de création est conservée. En cas de succès,
  /// les réactions du contenu et leur nombre sont rechargés.
  ///
  /// - [contentId] : identifiant du contenu auquel réagir.
  /// - [avatarText] : bedbug choisi.
  /// - [bubbleText] : bulle de texte.
  /// - [colorArgb] : couleur de l'effet ghost du bedbug en ARGB 32 bits.
  /// - [ghostSpeed] : intensité de l'effet ghost du bedbug.
  /// - [previousReaction] : réaction actuelle de l'utilisateur sur ce contenu, `null` s'il n'a pas encore réagi.
  Future<String?> save({
    required String contentId,
    required String avatarText,
    required int colorArgb,
    required double ghostSpeed,
    required String bubbleText,
    Reaction? previousReaction,
  }) async {
    state = const AsyncLoading();
    final now = DateTime.now();
    final result = await _saveReactionUsecase(
      SaveReactionParams(
        reaction: Reaction(
          id: UuidX.generate(),
          createdAt: previousReaction?.createdAt ?? now,
          updatedAt: now,
          contentId: contentId,
          authorId: localSignatureId,
          avatarText: avatarText,
          bubbleText: bubbleText,
          colorArgb: colorArgb,
          ghostSpeed: ghostSpeed,
        ),
      ),
    );
    state = const AsyncData(null);

    return result.fold(
      onFailure: (SaveReactionFailure failure) {
        return switch (failure) {
          SaveReactionFailure.invalidReaction => ref.l10n.reactionInvalidError,
          SaveReactionFailure.storageError => ref.l10n.homeGetContentsStorageError,
          SaveReactionFailure.unknown => ref.l10n.reactionSaveError,
        };
      },
      onSuccess: (_) {
        ref.invalidate(contentReactionsNotifierProvider(contentId));
        ref.invalidate(contentReactionCountNotifierProvider(contentId));
        return null;
      },
    );
  }
}
