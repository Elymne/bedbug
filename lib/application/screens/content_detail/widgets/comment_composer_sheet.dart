import 'package:bedbug/application/notifiers/save_comment_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Feuille de saisie d'un commentaire sur un contenu.
///
/// Le commentaire est signé par la signature de l'utilisateur, il n'y a donc
/// que le texte à saisir. Se ferme une fois le commentaire enregistré. À
/// afficher via [show].
class CommentComposerSheet extends ConsumerStatefulWidget {
  /// Crée un [CommentComposerSheet].
  ///
  /// - [contentId] : identifiant du contenu à commenter.
  const CommentComposerSheet({super.key, required this.contentId});

  /// Identifiant du contenu à commenter.
  final String contentId;

  /// Affiche la feuille de saisie de commentaire.
  ///
  /// - [context] : contexte depuis lequel ouvrir la feuille.
  /// - [contentId] : identifiant du contenu à commenter.
  static Future<void> show(BuildContext context, {required String contentId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => CommentComposerSheet(contentId: contentId),
    );
  }

  @override
  ConsumerState<CommentComposerSheet> createState() => _State();
}

class _State extends ConsumerState<CommentComposerSheet> {
  /// Contrôle du corps du commentaire.
  late final _bodyControl = FormControl<String>(validators: [AppValidators.required, AppValidators.commentBody]);

  /// Formulaire du commentaire.
  late final FormGroup _form = FormGroup({'body': _bodyControl});

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    final saveCommentNotifierWatcher = ref.watch(saveCommentNotifierProvider);

    return Padding(
      // Remonte la feuille au-dessus du clavier pendant la saisie.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppValues.baseMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(
                l10n.commentComposerTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onLight),
              ),
              ReactiveTextField<String>(
                formControl: _bodyControl,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                maxLength: maxCommentLength,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(labelText: l10n.commentBodyLabel),
                validationMessages: {
                  ValidationMessage.required: (_) => l10n.createRequiredFieldError,
                  'commentBody': (_) => l10n.commentBodyError(maxCommentLength),
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AppGradientButton(
                  isLoading: saveCommentNotifierWatcher.isLoading,
                  onTap: _onSave,
                  child: Text(l10n.commentSaveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Valide le formulaire, enregistre le commentaire puis ferme la feuille.
  ///
  /// En cas d'échec, la feuille reste ouverte et l'erreur est affichée.
  Future<void> _onSave() async {
    if (!_form.valid) {
      _form.markAllAsTouched();
      return;
    }

    final failureMessage = await ref
        .read(saveCommentNotifierProvider.notifier)
        .save(contentId: widget.contentId, body: _bodyControl.value!);
    if (!mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      return;
    }
    context.pop();
  }
}
