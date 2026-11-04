import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/settings/settings_language_tile/settings_language_tile.widget.dart';
import 'package:bedbug/application/screens/settings/settings_menu_tile/settings_menu_tile.widget.dart';
import 'package:bedbug/application/screens/settings/settings_profile_tile/settings_profile_tile.widget.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page des paramètres de l'application : le menu de tous les réglages.
///
/// Chaque réglage a sa propre page, ouverte depuis une ligne du menu. La
/// description de la ligne résume sa valeur quand elle tient en quelques mots
/// (pseudo, langue), et son rôle sinon. Page statique : les lignes qui affichent
/// une valeur l'observent elles-mêmes.
class SettingsScreen extends ConsumerWidget {
  /// Crée un [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    final menuTiles = [
      const SettingsProfileTile(),
      const SettingsLanguageTile(),
      SettingsMenuTile(
        icon: AppIcons.editNote,
        title: l10n.settingsPublishingTitle,
        subtitle: l10n.settingsPublishingSubtitle,
        path: settingsPublishingPath,
      ),
      SettingsMenuTile(
        icon: AppIcons.shield,
        title: l10n.trustSettingsTitle,
        subtitle: l10n.trustSettingsSubtitle,
        path: settingsTrustPath,
      ),
      SettingsMenuTile(
        icon: AppIcons.storage,
        title: l10n.settingsStorageTitle,
        subtitle: l10n.settingsStorageSubtitle,
        path: settingsStoragePath,
      ),
      SettingsMenuTile(
        icon: AppIcons.article,
        title: l10n.settingsOwnContentsTitle,
        subtitle: l10n.settingsOwnContentsSubtitle,
        path: settingsOwnContentsPath,
      ),
      SettingsMenuTile(
        icon: AppIcons.bug,
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
