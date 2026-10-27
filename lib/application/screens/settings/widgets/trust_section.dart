import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/trust_policy_editor.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/trust/domain/object_values/trust_settings.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réglages des domaines que l'app peut contacter : sort des domaines inconnus, listes des médias et des liens.
///
/// L'utilisateur garde la main sur tout ce que son téléphone charge : il
/// choisit ce que deviennent les contenus d'un domaine qu'il n'a classé
/// nulle part, et range chaque domaine en whitelist (affiché directement)
/// ou en greylist (flouté, affiché sur confirmation). Chaque changement est
/// enregistré et appliqué aussitôt.
class TrustSection extends ConsumerWidget {
  /// Crée un [TrustSection].
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final trustSettingsNotifierWatcher = ref.watch(trustSettingsNotifierProvider);

    return trustSettingsNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(l10n.homeGetContentsUnknown),
      data: (trustSettings) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.trustUnknownLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onLight),
            ),
            for (final behavior in UnknownDomainBehavior.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(switch (behavior) {
                  UnknownDomainBehavior.hidden => l10n.trustUnknownHidden,
                  UnknownDomainBehavior.blurred => l10n.trustUnknownBlurred,
                }),
                trailing: Visibility(
                  visible: behavior == trustSettings.unknownDomainBehavior,
                  child: const Icon(Icons.check, color: AppColors.primary),
                ),
                onTap: () {
                  _run(context, ref.read(trustSettingsNotifierProvider.notifier).setUnknownDomainBehavior(behavior));
                },
              ),
            const SizedBox(height: 16),
            Text(l10n.trustMediaTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TrustPolicyEditor(family: UrlFamily.media, policy: trustSettings.mediaPolicy),
            const SizedBox(height: 24),
            Text(l10n.trustLinksTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TrustPolicyEditor(family: UrlFamily.link, policy: trustSettings.linkPolicy),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _run(context, ref.read(trustSettingsNotifierProvider.notifier).resetToDefaults()),
              icon: const Icon(Icons.restore),
              label: Text(l10n.trustResetButton),
            ),
          ],
        );
      },
    );
  }

  /// Attend la modification [action] et affiche son éventuel message d'erreur.
  Future<void> _run(BuildContext context, Future<String?> action) async {
    final failureMessage = await action;
    if (failureMessage != null && context.mounted) {
      AppSnackbar.showError(context, failureMessage);
    }
  }
}
