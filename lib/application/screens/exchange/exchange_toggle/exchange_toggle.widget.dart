import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Case d'activation de l'échange de contenus avec les téléphones proches.
///
/// Désactivée le temps que l'échange démarre ou s'arrête ; un échec est signalé par une snackbar.
class ExchangeToggle extends ConsumerWidget {
  /// Crée un [ExchangeToggle].
  const ExchangeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passiveExchangeNotifierWatcher = ref.watch(passiveExchangeNotifierProvider);

    return Column(
      spacing: 8,
      children: [
        Text(context.loc.exchangeToggleLabel),
        Checkbox(
          value: passiveExchangeNotifierWatcher.value ?? false,
          onChanged: passiveExchangeNotifierWatcher.isLoading
              ? null
              : (isChecked) => _onToggle(context, ref, isEnabled: isChecked ?? false),
        ),
      ],
    );
  }

  /// Active ou coupe l'échange, et affiche l'erreur s'il y en a une.
  ///
  /// - [context] : contexte de la page.
  /// - [ref] : accès aux providers.
  /// - [isEnabled] : `true` pour activer l'échange.
  Future<void> _onToggle(BuildContext context, WidgetRef ref, {required bool isEnabled}) async {
    final failureMessage = await ref.read(passiveExchangeNotifierProvider.notifier).setEnabled(isEnabled: isEnabled);
    if (failureMessage != null && context.mounted) {
      AppSnackbar.showError(context, failureMessage);
    }
  }
}
