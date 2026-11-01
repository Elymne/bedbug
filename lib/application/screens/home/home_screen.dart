import 'package:bedbug/application/exchange/passive_exchange_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/home/home_bars_offset_notifier.dart';
import 'package:bedbug/application/screens/home/home_feed_notifier.dart';
import 'package:bedbug/application/screens/home/widgets/home_empty_feed.dart';
import 'package:bedbug/application/style/app_const.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'accueil de l'application.
class HomeScreen extends ConsumerStatefulWidget {
  /// Crée un [HomeScreen].
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _State();
}

class _State extends ConsumerState<HomeScreen> {
  /// Contrôleur de scroll de la liste de contenus.
  late final ScrollController _scrollController = ScrollController()..addListener(_handleScroll);

  /// Dernier offset de scroll connu, utilisé pour calculer le delta.
  double _lastOffset = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeFeedNotifierWatcher = ref.watch(homeFeedNotifierProvider);
    final passiveExchangeNotifierWatcher = ref.watch(passiveExchangeNotifierProvider);
    final navBarHeight = AppConst.homeNavBarBaseHeight + MediaQuery.paddingOf(context).bottom;
    final l10n = context.loc;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final hiddenOffset = ref.watch(homeBarsOffsetNotifierProvider);
                return _buildCollapsible(
                  fullHeight: AppConst.homeSearchBarHeight,
                  hiddenExtent: hiddenOffset.clamp(0, AppConst.homeSearchBarHeight),
                  alignment: Alignment.bottomCenter,
                  child: child!,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ContentSearchInput(
                  hintText: context.loc.searchHint,
                  isReadOnly: true,
                  onTap: () => context.push(searchPath),
                ),
              ),
            ),
            Expanded(
              child: homeFeedNotifierWatcher.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(child: CircularProgressIndicator()),
                data: (state) {
                  return ContentListView(
                    contents: state.contents,
                    emptyChild: const HomeEmptyFeed(),
                    controller: _scrollController,
                    onRefresh: ref.read(homeFeedNotifierProvider.notifier).refresh,
                    unviewedContentIds: state.unviewedContentIds,
                    onContentViewed: ref.read(homeFeedNotifierProvider.notifier).markViewed,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final hiddenOffset = ref.watch(homeBarsOffsetNotifierProvider);
          return _buildCollapsible(
            fullHeight: navBarHeight,
            hiddenExtent: hiddenOffset.clamp(0, navBarHeight),
            alignment: Alignment.topCenter,
            child: child!,
          );
        },
        child: AppNavBar(
          selectedIndex: 0,
          items: [
            AppNavBarItem(icon: AppIcons.home, label: l10n.navHomeLabel),
            AppNavBarItem(icon: AppIcons.add, label: l10n.navCreateLabel),
            AppNavBarItem(
              icon: AppIcons.bluetooth,
              label: l10n.navExchangeLabel,
              isGhosting: passiveExchangeNotifierWatcher.value ?? false,
            ),
            AppNavBarItem(icon: AppIcons.settings, label: l10n.navSettingsLabel),
          ],
          onTap: (index) {
            if (index == 1) {
              context.push(createPath);
              return;
            }
            if (index == 2) {
              context.push(exchangePath);
              return;
            }
            if (index == 3) {
              // `push` et non `go` : la page s'empile au-dessus de la home,
              // pour que le retour système y ramène au lieu de quitter l'app.
              context.push(settingsPath);
            }
          },
        ),
      ),
    );
  }

  /// Répercute le delta de scroll sur la sortie d'écran des barres.
  void _handleScroll() {
    final currentOffset = _scrollController.position.pixels;
    final delta = currentOffset - _lastOffset;
    _lastOffset = currentOffset;
    if (delta == 0) return;
    ref.read(homeBarsOffsetNotifierProvider.notifier).applyScrollDelta(delta);
  }

  /// Découpe [child] pour ne montrer que la portion visible une fois [hiddenExtent] pixels
  /// sortis de l'écran, en clippant la portion opposée à [alignment].
  Widget _buildCollapsible({
    required double fullHeight,
    required double hiddenExtent,
    required Alignment alignment,
    required Widget child,
  }) {
    return ClipRect(
      child: SizedBox(
        height: fullHeight - hiddenExtent,
        child: OverflowBox(
          minHeight: fullHeight,
          maxHeight: fullHeight,
          alignment: alignment,
          child: SizedBox(height: fullHeight, child: child),
        ),
      ),
    );
  }
}
