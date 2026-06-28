import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Scaffold principal de l'application avec la [AppNavBar].
class Shell extends ConsumerWidget {
  /// Crée un [Shell].
  const Shell({super.key, required this.navigationShell});

  /// Shell de navigation fourni par GoRouter.
  final StatefulNavigationShell navigationShell;

  /// Convertit l'index de branche (0=home, 1=settings) en index navbar (0=home, 2=settings).
  int get _navSelectedIndex => navigationShell.currentIndex == 0 ? 0 : 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: _navSelectedIndex,
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
          context.go(index == 0 ? homePath : settingsPath);
        },
      ),
    );
  }
}
