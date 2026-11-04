import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/screens/home/home.config.dart';
import 'package:bedbug/application/screens/home/home_exchange_arrow/home_exchange_arrow.widget.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Espace entre la flèche et le haut de la barre de navigation.
const double _kArrowBottomGap = 8;

/// État vide du flux de la home page.
///
/// Les contenus n'arrivent que des téléphones croisés : tant que l'échange est coupé, l'accueil resterait vide
/// sans que l'utilisateur sache pourquoi. Le conseil, et une flèche juste au-dessus de l'onglet d'échange, mènent
/// l'utilisateur à la page qui l'active. Tous deux disparaissent dès que l'échange tourne : il n'y a alors plus qu'à
/// attendre une rencontre.
class HomeEmptyFeed extends ConsumerWidget {
  /// Crée un [HomeEmptyFeed].
  const HomeEmptyFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passiveExchangeNotifierWatcher = ref.watch(passiveExchangeNotifierProvider);
    final l10n = context.loc;
    final isExchangeOff = passiveExchangeNotifierWatcher.value == false;

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text(l10n.homeEmptyList, textAlign: TextAlign.center),
                if (isExchangeOff)
                  Text(
                    l10n.homeEmptyExchangeHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.disabled),
                  ),
              ],
            ),
          ),
        ),
        // Même grille que la barre de navigation (des onglets de même largeur, dans le sens de lecture) : la flèche,
        // centrée dans la colonne de l'onglet d'échange, tombe pile au-dessus de son icône.
        if (isExchangeOff)
          Positioned(
            left: 0,
            right: 0,
            bottom: _kArrowBottomGap,
            child: Row(
              children: [
                for (var index = 0; index < homeNavItemCount; index++)
                  Expanded(
                    child: index == homeExchangeNavIndex
                        ? const Center(child: HomeExchangeArrow())
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
