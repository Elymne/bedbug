import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/home/home_notifier.dart';
import 'package:bedbug/application/screens/home/widgets/content_list_view.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'accueil de l'application.
class HomeScreen extends ConsumerWidget {
  /// Crée un [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeNotifierWatcher = ref.watch(homeNotifierProvider);
    final l10n = context.loc;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: ContentSearchInput(hintText: 'Rechercher…'),
            ),
            Expanded(
              child: homeNotifierWatcher.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(child: CircularProgressIndicator()),
                data: (state) => ContentListView(contents: state.contents),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavBar(
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
    );
  }
}
