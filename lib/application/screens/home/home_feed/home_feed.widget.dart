import 'package:bedbug/application/screens/home/home_collapsible_bar/home_collapsible_bar.notifier.dart';
import 'package:bedbug/application/screens/home/home_empty_feed/home_empty_feed.widget.dart';
import 'package:bedbug/application/screens/home/home_feed/home_feed.notifier.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flux de contenus de la page d'accueil.
///
/// Seul widget de la home à observer le flux : son chargement ou son rechargement ne reconstruit que la liste, pas
/// les barres qui l'entourent. Il remonte aussi chaque déplacement du scroll vertical pour que la searchbar et la
/// navbar sortent de l'écran au fil de la lecture.
class HomeFeed extends ConsumerWidget {
  /// Crée un [HomeFeed].
  const HomeFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeFeedNotifierWatcher = ref.watch(homeFeedNotifierProvider);

    return homeFeedNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: CircularProgressIndicator()),
      data: (state) {
        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            final delta = notification.scrollDelta;
            // Seul le scroll vertical de la liste elle-même déplace les barres, pas celui d'un carrousel imbriqué.
            if (notification.depth != 0 || notification.metrics.axis != Axis.vertical || delta == null) {
              return false;
            }
            if (delta == 0) {
              return false;
            }
            ref.read(homeCollapsibleBarNotifierProvider.notifier).applyScrollDelta(delta);
            return false;
          },
          child: ContentListView(
            contents: state.contents,
            emptyChild: const HomeEmptyFeed(),
            onRefresh: ref.read(homeFeedNotifierProvider.notifier).refresh,
            unviewedContentIds: state.unviewedContentIds,
            onContentViewed: ref.read(homeFeedNotifierProvider.notifier).markViewed,
          ),
        );
      },
    );
  }
}
