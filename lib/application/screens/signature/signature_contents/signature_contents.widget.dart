import 'package:bedbug/application/notifiers/search_results.notifier.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contenus signés par une signature, sous l'en-tête de sa page.
///
/// Seule partie de la page à observer la recherche des contenus : leur chargement ne reconstruit pas l'en-tête.
class SignatureContents extends ConsumerWidget {
  /// Crée un [SignatureContents].
  ///
  /// - [signatureId] : identifiant de la signature dont les contenus sont listés.
  const SignatureContents({super.key, required this.signatureId});

  /// Identifiant de la signature dont les contenus sont listés.
  final String signatureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final searchResultsNotifierWatcher = ref.watch(searchResultsNotifierProvider(SignatureSearchCriteria(signatureId)));

    return searchResultsNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.homeGetContentsUnknown)),
      data: (state) {
        return ContentListView(
          contents: state.contents,
          emptyChild: Center(child: Text(state.failureMessage ?? l10n.signatureContentsEmpty)),
        );
      },
    );
  }
}
