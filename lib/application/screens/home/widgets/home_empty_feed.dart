import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État vide du flux de la home page.
class HomeEmptyFeed extends ConsumerWidget {
  /// Crée un [HomeEmptyFeed].
  const HomeEmptyFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(child: Text(context.loc.homeEmptyList));
  }
}
