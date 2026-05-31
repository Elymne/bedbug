import 'package:bedbug/application/screens/home/content_list_view.dart';
import 'package:bedbug/application/screens/home/home_notifier.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page d'accueil de l'application.
class HomeScreen extends ConsumerWidget {
  /// Crée un [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeNotifierWatcher = ref.watch(homeNotifierProvider);

    return Scaffold(
      body: Column(
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
    );
  }
}
