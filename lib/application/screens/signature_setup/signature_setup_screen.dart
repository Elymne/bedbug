import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/signature/app_signature_form.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de création de la signature, première page vue après l'installation.
///
/// Tant que l'appareil n'a pas de signature, le splashscreen amène ici plutôt
/// que sur l'accueil : les contenus publiés et les réactions portent la
/// signature locale, autant la choisir avant de commencer. La page n'a pas de
/// bouton retour ni de passage direct à l'accueil, l'enregistrement est la
/// seule sortie.
class SignatureSetupScreen extends ConsumerWidget {
  /// Crée un [SignatureSetupScreen].
  const SignatureSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppValues.baseMargin, 32, AppValues.baseMargin, 32),
          children: [
            Text(
              l10n.signatureSetupTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DynaPuff',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.onLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.signatureSetupSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onLighter),
            ),
            const SizedBox(height: 16),
            AppSignatureForm(
              signature: null,
              submitLabel: l10n.signatureSetupSubmit,
              onSaved: () => context.go(homePath),
            ),
          ],
        ),
      ),
    );
  }
}
