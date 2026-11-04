import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Barre de navigation de la page d'accueil.
///
/// Observe l'échange passif pour faire « fantômer » l'onglet d'échange tant qu'il tourne : l'utilisateur voit d'un
/// coup d'œil que son téléphone cherche des pairs, sans ouvrir la page.
class HomeNavBar extends ConsumerWidget {
  /// Crée un [HomeNavBar].
  const HomeNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passiveExchangeNotifierWatcher = ref.watch(passiveExchangeNotifierProvider);
    final l10n = context.loc;

    return AppNavBar(
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
    );
  }
}
