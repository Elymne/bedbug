import 'package:bedbug/application/l10n/locale_display_name_x.dart';
import 'package:bedbug/application/l10n/locale_notifier.dart';
import 'package:bedbug/application/notifiers/local_signature_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/settings/widgets/settings_menu_tile.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page des paramètres de l'application : le menu de tous les réglages.
///
/// Chaque réglage a sa propre page, ouverte depuis une ligne du menu. La
/// description de la ligne résume sa valeur quand elle tient en quelques mots
/// (pseudo, langue), et son rôle sinon.
class SettingsScreen extends ConsumerWidget {
  /// Crée un [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final localSignatureNotifierWatcher = ref.watch(localSignatureNotifierProvider);
    final pseudo = localSignatureNotifierWatcher.value?.signature?.pseudo;
    final locale = ref.watch(localeNotifierProvider);

    final menuTiles = [
      SettingsMenuTile(
        icon: Icons.person_outline,
        title: l10n.settingsProfileTitle,
        subtitle: pseudo ?? l10n.settingsProfileNotConfigured,
        subtitlePrefix: pseudo == null ? null : AppPrefixes.signature,
        path: settingsSignaturePath,
      ),
      SettingsMenuTile(
        icon: Icons.translate,
        title: l10n.settingsLanguageTitle,
        subtitle: locale.displayName,
        path: settingsLanguagePath,
      ),
      SettingsMenuTile(
        icon: Icons.edit_note_outlined,
        title: l10n.settingsPublishingTitle,
        subtitle: l10n.settingsPublishingSubtitle,
        path: settingsPublishingPath,
      ),
      SettingsMenuTile(
        icon: Icons.shield_outlined,
        title: l10n.trustSettingsTitle,
        subtitle: l10n.trustSettingsSubtitle,
        path: settingsTrustPath,
      ),
      SettingsMenuTile(
        icon: Icons.storage_outlined,
        title: l10n.settingsStorageTitle,
        subtitle: l10n.settingsStorageSubtitle,
        path: settingsStoragePath,
      ),
      SettingsMenuTile(
        icon: Icons.article_outlined,
        title: l10n.settingsOwnContentsTitle,
        subtitle: l10n.settingsOwnContentsSubtitle,
        path: settingsOwnContentsPath,
      ),
      SettingsMenuTile(
        icon: Icons.bug_report_outlined,
        title: l10n.settingsDebugTitle,
        subtitle: l10n.settingsDebugSubtitle,
        path: settingsDebugPath,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: l10n.navSettingsLabel, onBack: context.pop),
            Expanded(
              child: ListView.separated(
                itemCount: menuTiles.length,
                separatorBuilder: (context, index) => const AppListSeparator(),
                itemBuilder: (context, index) => menuTiles[index],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
