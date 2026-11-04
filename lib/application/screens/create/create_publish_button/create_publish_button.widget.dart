import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.widget.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Bouton de publication de la page de création.
///
/// Reste grisé tant que le contenu n'est pas publiable, et se réévalue à chaque changement du formulaire. Une fois le
/// contenu publié, il ouvre son détail ; en cas d'échec, il affiche l'erreur et laisse le formulaire intact.
class CreatePublishButton extends ConsumerWidget {
  /// Crée un [CreatePublishButton].
  const CreatePublishButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveValueListenableBuilder<Map<String, Object?>>(
      formControl: ref.read(createFormNotifierProvider.notifier).form,
      builder: (context, control, child) {
        return AppGradientButton(
          onTap: ref.read(createFormNotifierProvider.notifier).isPublishable ? () => _publish(context, ref) : null,
          child: Text(AppLocalizations.of(context)!.createSaveButton),
        );
      },
    );
  }

  /// Publie le contenu saisi, puis ouvre son détail ou affiche l'erreur.
  ///
  /// - [context] : contexte depuis lequel afficher le résultat et naviguer.
  /// - [ref] : accès au formulaire de création.
  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(createFormNotifierProvider.notifier).publish();
    if (result == null || !context.mounted) {
      return;
    }
    final savedContent = result.right;
    if (savedContent == null) {
      AppSnackbar.showError(context, result.left!);
      return;
    }
    AppSnackbar.showSuccess(context, AppLocalizations.of(context)!.createSuccessMessage);
    // Remplace la page de création par le détail du contenu créé : un retour
    // ramène alors directement à la page d'où la création a été lancée.
    context.pushReplacement(contentDetailPath, extra: savedContent);
  }
}
