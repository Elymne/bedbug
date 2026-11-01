import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'un réglage ouverte depuis le menu des paramètres : un en-tête avec retour, puis le réglage qui défile.
class SettingsSectionScreen extends ConsumerWidget {
  /// Crée un [SettingsSectionScreen].
  ///
  /// - [titleOf] : retourne le titre de la page dans la langue donnée.
  /// - [child] : réglage affiché par la page.
  const SettingsSectionScreen({super.key, required this.titleOf, required this.child});

  /// Retourne le titre de la page dans la langue donnée.
  ///
  /// Une fonction plutôt qu'un texte : résolu à chaque build de la page, le
  /// titre suit un changement de langue fait depuis la page elle-même.
  final String Function(AppLocalizations l10n) titleOf;

  /// Réglage affiché par la page.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: titleOf(context.loc), onBack: context.pop),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppValues.baseMargin, 8, AppValues.baseMargin, 32),
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
