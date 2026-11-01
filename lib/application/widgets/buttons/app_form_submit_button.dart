import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Bouton d'envoi d'un formulaire, désactivé tant que [form] n'est pas valide.
///
/// Montre d'emblée que le formulaire est incomplet, plutôt que de le signaler
/// après un tap.
class AppFormSubmitButton extends ConsumerWidget {
  /// Crée un [AppFormSubmitButton].
  ///
  /// - [form] : formulaire dont la validité active le bouton.
  /// - [onTap] : callback déclenché au tap.
  /// - [child] : contenu affiché dans le bouton.
  /// - [isLoading] : `true` pour afficher le loader et désactiver le tap.
  const AppFormSubmitButton({
    super.key,
    required this.form,
    required this.onTap,
    required this.child,
    this.isLoading = false,
  });

  /// Formulaire dont la validité active le bouton.
  final FormGroup form;

  /// Callback déclenché au tap.
  final VoidCallback onTap;

  /// Contenu affiché dans le bouton.
  final Widget child;

  /// Indique si le bouton est en état de chargement.
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<ControlStatus>(
      stream: form.statusChanged,
      initialData: form.status,
      builder: (context, _) {
        return AppGradientButton(isLoading: isLoading, onTap: form.valid ? onTap : null, child: child);
      },
    );
  }
}
