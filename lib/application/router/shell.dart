import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paths correspondant à chaque index de la navbar.
const _kNavPaths = [homePath, createPath, settingsPath];

/// Scaffold principal de l'application avec la [AppNavBar].
class Shell extends ConsumerWidget {
  /// Crée un [Shell].
  const Shell({super.key, required this.navigationShell});

  /// Shell de navigation fourni par GoRouter.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        selectedIndex: navigationShell.currentIndex,
        items: [
          AppNavBarItem(icon: Icons.home_outlined, label: l10n.navHomeLabel),
          AppNavBarItem(
            icon: Icons.add_circle_outline,
            label: l10n.navCreateLabel,
          ),
          AppNavBarItem(
            icon: Icons.settings_outlined,
            label: l10n.navSettingsLabel,
          ),
        ],
        onTap: (index) => context.go(_kNavPaths[index]),
      ),
    );
  }
}
