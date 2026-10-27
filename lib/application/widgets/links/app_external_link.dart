import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/dialogs/trust_confirm_dialog.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/trust/domain/object_values/default_trust_settings.dart';
import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lien externe affiché en toutes lettres, ouvert dans le navigateur selon le niveau de confiance de son domaine.
///
/// Un lien de la whitelist s'ouvre directement. Un lien de la greylist, ou
/// d'un domaine inconnu, demande d'abord confirmation en citant son
/// domaine. Une adresse piégée n'est jamais ouverte : elle reste affichée
/// en texte simple, pour que l'utilisateur voie ce qu'on a voulu lui faire
/// ouvrir. Seule l'adresse vérifiée est confiée au navigateur.
class AppExternalLink extends ConsumerWidget {
  /// Crée un [AppExternalLink].
  ///
  /// - [url] : adresse du lien, telle que reçue.
  /// - [style] : style du texte du lien.
  const AppExternalLink({super.key, required this.url, this.style});

  /// Adresse du lien, telle que reçue.
  final String url;

  /// Style du texte du lien.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeUrl = SafeUrl.tryParse(url);
    if (safeUrl == null) {
      return Text(url, style: style);
    }

    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => _open(context, ref, safeUrl),
        child: Text(
          url,
          style: (style ?? const TextStyle()).copyWith(color: AppColors.info, decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  /// Ouvre [safeUrl] dans le navigateur, après confirmation si son domaine n'est pas de confiance.
  Future<void> _open(BuildContext context, WidgetRef ref, SafeUrl safeUrl) async {
    final l10n = context.loc;
    final trustSettings = ref.read(trustSettingsNotifierProvider).value ?? defaultTrustSettings;
    final trust = trustSettings.linkPolicy.evaluate(safeUrl.url);
    if (trust == UrlTrust.invalid) {
      return;
    }
    if (trust != UrlTrust.trusted) {
      final isConfirmed = await TrustConfirmDialog.show(
        context,
        title: l10n.linkOpenTitle,
        body: l10n.linkOpenBody(safeUrl.host),
        confirmLabel: l10n.linkOpenConfirm,
      );
      if (!isConfirmed) {
        return;
      }
    }

    final isOpened = await launchUrl(Uri.parse(safeUrl.url), mode: LaunchMode.externalApplication);
    if (!isOpened && context.mounted) {
      AppSnackbar.showError(context, l10n.linkOpenError);
    }
  }
}
