import 'package:bedbug/application/screens/home/content_list.dart';
import 'package:bedbug/application/screens/home/home_notifier.dart';
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
      body: homeNotifierWatcher.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: CircularProgressIndicator()),
        data: (state) => ContentList(contents: state.contents),
      ),
    );
  }
}
