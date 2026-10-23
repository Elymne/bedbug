import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/settings/local_user_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/own_contents_section.dart';
import 'package:bedbug/application/screens/settings/widgets/profile_section.dart';
import 'package:bedbug/application/screens/settings/widgets/publishing_section.dart';
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
    final localUserNotifierWatcher = ref.watch(localUserNotifierProvider);
    final pseudo = localUserNotifierWatcher.value?.user?.pseudo;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: l10n.navSettingsLabel, onBack: () => context.go(homePath)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                children: [
                  AppExpandableSection(
                    title: l10n.settingsProfileTitle,
                    subtitle: pseudo == null ? l10n.settingsProfileNotConfigured : 'u/$pseudo',
                    icon: Icons.person_outline,
                    child: localUserNotifierWatcher.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Text(l10n.homeGetContentsUnknown),
                      data: (state) {
                        if (state.failureMessage != null) {
                          return Text(state.failureMessage!);
                        }
                        return ProfileSection(user: state.user);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppExpandableSection(
                    title: l10n.settingsPublishingTitle,
                    icon: Icons.edit_note_outlined,
                    child: const PublishingSection(),
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
