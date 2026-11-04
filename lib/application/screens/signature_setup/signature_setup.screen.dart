import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/signature_setup/signature_info_dialog/signature_info_dialog.widget.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/signature/app_signature_form.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
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
///
/// À l'arrivée, une popup ([SignatureInfoDialog]) explique ce qu'est une
/// signature, et surtout qu'il ne s'agit pas d'un compte utilisateur.
class SignatureSetupScreen extends ConsumerStatefulWidget {
  /// Crée un [SignatureSetupScreen].
  const SignatureSetupScreen({super.key});

  @override
  ConsumerState<SignatureSetupScreen> createState() => _State();
}

class _State extends ConsumerState<SignatureSetupScreen> {
  /// Ouvre la popup d'explication une fois la page affichée.
  ///
  /// Une popup ne peut s'ouvrir qu'après la première frame : la page doit exister dans le navigateur pour servir de
  /// fond à la popup.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      SignatureInfoDialog.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
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
