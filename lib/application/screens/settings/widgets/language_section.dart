import 'package:bedbug/application/l10n/locale_display_name_x.dart';
import 'package:bedbug/application/l10n/locale_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choix de la langue de l'application : une ligne par langue proposée, la langue active cochée.
///
/// La langue change dès le tap, sans bouton « Enregistrer », et toute
/// l'interface bascule aussitôt, sens de lecture compris pour l'arabe.
class LanguageSection extends ConsumerWidget {
  /// Crée un [LanguageSection].
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    return Column(
      children: [
        for (final code in LocaleNotifier.supportedCodes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(Locale(code).displayName, style: const TextStyle(fontSize: 15, color: AppColors.onLight)),
            trailing: code == locale.languageCode ? const AppIcon(AppIcons.check, color: AppColors.primary) : null,
            onTap: () => ref.read(localeNotifierProvider.notifier).setLocale(Locale(code)),
          ),
      ],
    );
  }
}
