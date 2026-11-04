import 'package:bedbug/application/l10n/locale_display_name_x.dart';
import 'package:bedbug/application/notifiers/locale.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/settings/settings_menu_tile/settings_menu_tile.widget.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ligne du menu des paramètres menant au choix de la langue, qui affiche la langue active.
///
/// Seule partie du menu à observer la langue : la ligne suit un changement fait depuis la page de la langue.
class SettingsLanguageTile extends ConsumerWidget {
  /// Crée un [SettingsLanguageTile].
  const SettingsLanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    return SettingsMenuTile(
      icon: AppIcons.translate,
      title: context.loc.settingsLanguageTitle,
      subtitle: locale.displayName,
      path: settingsLanguagePath,
    );
  }
}
