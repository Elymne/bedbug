import 'package:bedbug/application/notifiers/revealed_urls_notifier.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/dialogs/trust_confirm_dialog.dart';
import 'package:bedbug/application/widgets/media/app_media_placeholder.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Voile posé sur un média d'un domaine inconnu, qui demande une confirmation avant d'être chargé.
///
/// Rien n'est chargé : le voile n'affiche que le domaine, pour que
/// l'utilisateur sache quel site son téléphone contactera. Un tap demande
/// confirmation, puis dévoile le média pour le reste de la session.
class AppMediaVeil extends ConsumerWidget {
  /// Crée un [AppMediaVeil].
  ///
  /// - [url] : adresse du média voilé, telle que reçue.
  /// - [host] : domaine du média, cité à l'utilisateur.
  const AppMediaVeil({super.key, required this.url, required this.host});

  /// Adresse du média voilé, telle que reçue.
  final String url;

  /// Domaine du média, cité à l'utilisateur.
  final String host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    return Semantics(
      button: true,
      label: l10n.mediaRevealTitle,
      child: GestureDetector(
        onTap: () => _confirmReveal(context, ref),
        child: AppMediaPlaceholder(icon: AppIcons.eyeOff, label: l10n.mediaHiddenLabel(host)),
      ),
    );
  }

  /// Demande confirmation, puis dévoile le média pour le reste de la session.
  Future<void> _confirmReveal(BuildContext context, WidgetRef ref) async {
    final l10n = context.loc;
    final isConfirmed = await TrustConfirmDialog.show(
      context,
      title: l10n.mediaRevealTitle,
      body: l10n.mediaRevealBody(host),
      confirmLabel: l10n.mediaRevealConfirm,
    );
    if (isConfirmed) {
      ref.read(revealedUrlsNotifierProvider.notifier).reveal(url);
    }
  }
}
