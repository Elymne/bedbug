import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Séparateur entre deux éléments d'une liste, en retrait des bords.
class AppListSeparator extends ConsumerWidget {
  /// Crée un [AppListSeparator].
  const AppListSeparator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: AppColors.border);
  }
}
