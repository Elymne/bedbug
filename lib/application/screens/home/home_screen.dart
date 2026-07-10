import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/home/home_notifier.dart';
import 'package:bedbug/application/screens/home/widgets/content_list_view.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur totale de la searchbar, padding vertical compris.
const double _searchBarHeight = 84;

/// Hauteur fixe de la navbar, hors zone de sécurité du bas.
const double _navBarBaseHeight = 56;

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
    final homeNotifierWatcher = ref.watch(homeNotifierProvider);
    final hiddenOffset = homeNotifierWatcher.value?.barsHiddenOffset ?? 0;
    final navBarHeight = _navBarBaseHeight + MediaQuery.paddingOf(context).bottom;
    final l10n = context.loc;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCollapsible(
              fullHeight: _searchBarHeight,
              hiddenExtent: hiddenOffset.clamp(0, _searchBarHeight),
              alignment: Alignment.bottomCenter,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: ContentSearchInput(hintText: 'Rechercher…'),
              ),
            ),
            Expanded(
              child: homeNotifierWatcher.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(child: CircularProgressIndicator()),
                data: (state) => ContentListView(contents: state.contents, controller: _scrollController),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCollapsible(
        fullHeight: navBarHeight,
        hiddenExtent: hiddenOffset.clamp(0, navBarHeight),
        alignment: Alignment.topCenter,
        child: AppNavBar(
          selectedIndex: 0,
          items: [
            AppNavBarItem(icon: Icons.home, label: l10n.navHomeLabel),
            AppNavBarItem(icon: Icons.add_circle, label: l10n.navCreateLabel),
            AppNavBarItem(icon: Icons.settings, label: l10n.navSettingsLabel),
          ],
          onTap: (index) {
            if (index == 1) {
              context.push(createPath);
              return;
            }
            if (index == 2) {
              context.go(settingsPath);
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
    ref.read(homeNotifierProvider.notifier).applyScrollDelta(delta);
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
