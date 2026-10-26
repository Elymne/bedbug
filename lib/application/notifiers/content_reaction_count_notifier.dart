import 'package:bedbug/features/content/domain/usecases/count_content_reactions_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentReactionCountNotifier], un par identifiant de contenu.
final contentReactionCountNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ContentReactionCountNotifier, int, String>(ContentReactionCountNotifier.new);

/// Notifier chargeant le nombre de réactions d'un contenu, affiché en tag à côté des bounces.
class ContentReactionCountNotifier extends AsyncNotifier<int> {
  /// Crée un [ContentReactionCountNotifier].
  ///
  /// - [contentId] : identifiant du contenu dont on compte les réactions.
  ContentReactionCountNotifier(this.contentId);

  /// Identifiant du contenu dont on compte les réactions.
  final String contentId;

  /// Cas d'usage de comptage des réactions d'un contenu.
  late final _countContentReactionsUsecase = ref.read(countContentReactionsUsecaseProvider);

  @override
  Future<int> build() async {
    final result = await _countContentReactionsUsecase(CountContentReactionsParams(contentId: contentId));
    // Un comptage illisible n'empêche pas d'afficher le contenu : le tag
    // annonce alors simplement zéro réaction.
    return result.right ?? 0;
  }
}
