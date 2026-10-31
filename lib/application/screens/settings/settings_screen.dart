import 'package:bedbug/application/l10n/locale_display_name_x.dart';
import 'package:bedbug/application/l10n/locale_notifier.dart';
import 'package:bedbug/application/screens/settings/local_signature_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/language_section.dart';
import 'package:bedbug/application/screens/settings/widgets/own_contents_section.dart';
import 'package:bedbug/application/screens/settings/widgets/publishing_section.dart';
import 'package:bedbug/application/screens/settings/widgets/signature_section.dart';
import 'package:bedbug/application/screens/settings/widgets/storage_section.dart';
import 'package:bedbug/application/screens/settings/widgets/trust_section.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/application/widgets/sections/app_expandable_section.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page des paramètres de l'application.
///
/// Chaque réglage vit dans sa propre section dépliable, repliée par défaut.
class SettingsScreen extends ConsumerWidget {
  /// Crée un [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final localSignatureNotifierWatcher = ref.watch(localSignatureNotifierProvider);
    final pseudo = localSignatureNotifierWatcher.value?.signature?.pseudo;
    final locale = ref.watch(localeNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: l10n.navSettingsLabel, onBack: context.pop),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                children: [
                  AppExpandableSection(
                    title: l10n.settingsProfileTitle,
                    subtitle: pseudo ?? l10n.settingsProfileNotConfigured,
                    subtitlePrefix: pseudo == null ? null : AppPrefixes.signature,
                    icon: Icons.person_outline,
                    child: localSignatureNotifierWatcher.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Text(l10n.homeGetContentsUnknown),
                      data: (state) {
                        if (state.failureMessage != null) {
                          return Text(state.failureMessage!);
                        }
                        return SignatureSection(signature: state.signature);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppExpandableSection(
                    title: l10n.settingsLanguageTitle,
                    subtitle: locale.displayName,
                    icon: Icons.translate,
                    child: const LanguageSection(),
                  ),
                  const SizedBox(height: 12),
                  AppExpandableSection(
                    title: l10n.settingsPublishingTitle,
                    icon: Icons.edit_note_outlined,
                    child: const PublishingSection(),
                  ),
                  const SizedBox(height: 12),
                  AppExpandableSection(
                    title: l10n.trustSettingsTitle,
                    subtitle: l10n.trustSettingsSubtitle,
                    icon: Icons.shield_outlined,
                    child: const TrustSection(),
                  ),
                  const SizedBox(height: 12),
                  AppExpandableSection(
                    title: l10n.settingsStorageTitle,
                    subtitle: l10n.settingsStorageSubtitle,
                    icon: Icons.storage_outlined,
                    child: const StorageSection(),
                  ),
                  const SizedBox(height: 12),
                  AppExpandableSection(
                    title: l10n.settingsOwnContentsTitle,
                    subtitle: l10n.settingsOwnContentsSubtitle,
                    icon: Icons.article_outlined,
                    child: const OwnContentsSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
