import 'package:bedbug/application/screens/settings/storage_limit_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/storage_limit_editor.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réglage du poids maximal que les contenus peuvent occuper sur l'appareil.
class StorageSection extends ConsumerWidget {
  /// Crée un [StorageSection].
  const StorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final storageLimitNotifierWatcher = ref.watch(storageLimitNotifierProvider);

    ref.listen(storageLimitNotifierProvider, (previous, next) {
      if (next.isLoading) return;
      final failureMessage = next.value?.failureMessage;
      if (failureMessage != null) {
        AppSnackbar.showError(context, failureMessage);
      }
    });

    return storageLimitNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(l10n.homeGetContentsUnknown),
      data: (state) => StorageLimitEditor(limitInBytes: state.limitInBytes),
    );
  }
}
