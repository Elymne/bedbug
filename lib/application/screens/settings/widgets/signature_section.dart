import 'package:bedbug/application/notifiers/local_signature_notifier.dart';
import 'package:bedbug/application/widgets/signature/app_signature_form.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modification de la signature du téléphone, une fois celle-ci chargée.
class SignatureSection extends ConsumerWidget {
  /// Crée un [SignatureSection].
  const SignatureSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final localSignatureNotifierWatcher = ref.watch(localSignatureNotifierProvider);

    return localSignatureNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(l10n.homeGetContentsUnknown),
      data: (state) {
        if (state.failureMessage != null) {
          return Text(state.failureMessage!);
        }
        return AppSignatureForm(
          signature: state.signature,
          submitLabel: l10n.settingsProfileSaveButton,
          onSaved: () => AppSnackbar.showSuccess(context, l10n.settingsProfileSaved),
        );
      },
    );
  }
}
