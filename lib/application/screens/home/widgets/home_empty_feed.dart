import 'package:bedbug/application/screens/home/home_feed_notifier.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État vide du flux de la home page, avec un bouton de génération de contenus factices.
///
/// Tant que l'appareil n'a reçu aucun contenu, la home page serait vide : le
/// bouton permet de remplir le flux pour tester l'app sans pair à proximité.
class HomeEmptyFeed extends ConsumerWidget {
  /// Crée un [HomeEmptyFeed].
  const HomeEmptyFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text(l10n.homeEmptyList),
          TextButton(
            onPressed: () {
              ref.read(homeFeedNotifierProvider.notifier).seedAndReload();
            },
            child: Text(l10n.homeSeedButton),
          ),
        ],
      ),
    );
  }
}
