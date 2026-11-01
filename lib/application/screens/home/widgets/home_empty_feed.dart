import 'package:bedbug/application/exchange/passive_exchange_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État vide du flux de la home page.
///
/// Les contenus n'arrivent que des téléphones croisés : tant que l'échange est coupé, l'accueil resterait vide
/// sans que l'utilisateur sache pourquoi. Le conseil disparaît dès que l'échange tourne, il n'y a alors plus qu'à
/// attendre une rencontre.
class HomeEmptyFeed extends ConsumerWidget {
  /// Crée un [HomeEmptyFeed].
  const HomeEmptyFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passiveExchangeNotifierWatcher = ref.watch(passiveExchangeNotifierProvider);
    final l10n = context.loc;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(l10n.homeEmptyList, textAlign: TextAlign.center),
            if (passiveExchangeNotifierWatcher.value == false)
              Text(
                l10n.homeEmptyExchangeHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.disabled),
              ),
          ],
        ),
      ),
    );
  }
}
