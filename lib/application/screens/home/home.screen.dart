import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/home/home.config.dart';
import 'package:bedbug/application/screens/home/home_collapsible_bar/home_collapsible_bar.widget.dart';
import 'package:bedbug/application/screens/home/home_feed/home_feed.widget.dart';
import 'package:bedbug/application/screens/home/home_nav_bar/home_nav_bar.widget.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.widget.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.config.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'accueil de l'application.
///
/// Page statique : elle ne fait qu'assembler la searchbar, le flux et la navbar. Chaque partie qui dépend d'un état
/// l'observe elle-même, pour que seule cette partie se reconstruise quand il change.
class HomeScreen extends ConsumerWidget {
  /// Crée un [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navBarHeight = appNavBarBaseHeight + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeCollapsibleBar(
              height: homeSearchBarHeight,
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ContentSearchInput(
                  hintText: context.loc.searchHint,
                  isReadOnly: true,
                  onTap: () => context.push(searchPath),
                ),
              ),
            ),
            const Expanded(child: HomeFeed()),
          ],
        ),
      ),
      bottomNavigationBar: HomeCollapsibleBar(
        height: navBarHeight,
        alignment: Alignment.topCenter,
        child: const HomeNavBar(),
      ),
    );
  }
}
