import 'package:bedbug/application/screens/settings/user_settings_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réglages liés à l'écriture de contenus.
///
/// Les réglages sont enregistrés dès qu'ils changent : une case à cocher
/// n'a pas besoin de bouton « Enregistrer ».
class PublishingSection extends ConsumerWidget {
  /// Crée un [PublishingSection].
  const PublishingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final userSettingsNotifierWatcher = ref.watch(userSettingsNotifierProvider);

    ref.listen(userSettingsNotifierProvider, (previous, next) {
      if (next.isLoading) return;
      final failureMessage = next.value?.failureMessage;
      if (failureMessage != null) {
        AppSnackbar.showError(context, failureMessage);
      }
    });

    return userSettingsNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(l10n.homeGetContentsUnknown),
      data: (state) {
        return CheckboxListTile(
          value: state.settings.isAnonymousByDefault,
          onChanged: (isChecked) {
            ref.read(userSettingsNotifierProvider.notifier).setAnonymousByDefault(isChecked ?? false);
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            l10n.settingsAnonymousByDefaultLabel,
            style: const TextStyle(fontSize: 15, color: AppColors.onLight),
          ),
          subtitle: Text(
            l10n.settingsAnonymousByDefaultDescription,
            style: const TextStyle(fontSize: 13, color: AppColors.disabled),
          ),
        );
      },
    );
  }
}
