import 'package:bedbug/usecases/reaction/count_content_reactions/count_content_reactions.params.dart';
import 'package:bedbug/usecases/reaction/count_content_reactions/count_content_reactions.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentStatsNotifier], un par identifiant de contenu.
final contentStatsNotifierProvider = AsyncNotifierProvider.autoDispose.family<ContentStatsNotifier, int, String>(
  ContentStatsNotifier.new,
);

/// Notifier chargeant le nombre de réactions d'un contenu, affiché en tag à côté des bounces.
class ContentStatsNotifier extends AsyncNotifier<int> {
  /// Crée un [ContentStatsNotifier].
  ///
  /// - [contentId] : identifiant du contenu dont on compte les réactions.
  ContentStatsNotifier(this.contentId);

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
