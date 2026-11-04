import 'package:bedbug/application/notifiers/local_signature.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/settings/settings_menu_tile/settings_menu_tile.widget.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ligne du menu des paramètres menant à la signature, qui affiche le pseudo choisi.
///
/// Seule partie du menu à observer la signature : un changement de pseudo ne reconstruit que cette ligne.
class SettingsProfileTile extends ConsumerWidget {
  /// Crée un [SettingsProfileTile].
  const SettingsProfileTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localSignatureNotifierWatcher = ref.watch(localSignatureNotifierProvider);
    final pseudo = localSignatureNotifierWatcher.value?.signature?.pseudo;
    final l10n = context.loc;

    return SettingsMenuTile(
      icon: AppIcons.person,
      title: l10n.settingsProfileTitle,
      subtitle: pseudo ?? l10n.settingsProfileNotConfigured,
      subtitlePrefix: pseudo == null ? null : signaturePrefix,
      path: settingsSignaturePath,
    );
  }
}
