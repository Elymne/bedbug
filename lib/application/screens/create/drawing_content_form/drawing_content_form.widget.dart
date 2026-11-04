import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/notifiers/drawing_draft.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/drawing/app_drawing_image.widget.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champs de création d'un contenu dessiné : le titre, et le dessin fait dans l'éditeur.
///
/// Les contrôles sont portés par le [CreateFormNotifier], qui valide et construit le contenu à la publication : ce
/// widget les affiche, et ouvre l'éditeur.
class DrawingContentForm extends ConsumerWidget {
  /// Crée un [DrawingContentForm].
  const DrawingContentForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: ref.read(createFormNotifierProvider.notifier).drawingTitleControl,
            textCapitalization: TextCapitalization.sentences,
            validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
            decoration: InputDecoration(labelText: l10n.createTextTitleLabel, hintText: l10n.createTitleHint),
          ),
        ),
        ReactiveValueListenableBuilder<Drawing>(
          formControl: ref.read(createFormNotifierProvider.notifier).drawingControl,
          builder: (context, control, _) {
            final drawing = control.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                if (drawing != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // La clé change avec le dessin : l'aperçu est recalculé après chaque passage dans l'éditeur.
                    child: AppDrawingImage(drawing: drawing, cacheKey: 'create-${drawing.hashCode}'),
                  ),
                if (control.invalid && control.touched)
                  Text(l10n.createDrawingRequiredError, style: const TextStyle(color: AppColors.failure)),
                FilledButton.icon(
                  onPressed: () => _openEditor(context, ref, drawing),
                  icon: const AppIcon(AppIcons.brush),
                  label: Text(drawing == null ? l10n.createDrawingButton : l10n.createDrawingEditButton),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Ouvre l'éditeur, et garde le dessin validé.
  ///
  /// Un brouillon laissé en cours passe avant tout : c'est le travail le
  /// plus récent, interrompu avant d'être validé. Sinon l'éditeur reprend
  /// [drawing], et sans dessin, la page de choix de la surface s'ouvre
  /// d'abord.
  ///
  /// - [context] : contexte depuis lequel naviguer.
  /// - [ref] : accès au brouillon et au formulaire de création.
  /// - [drawing] : dessin à reprendre, `null` pour en commencer un.
  Future<void> _openEditor(BuildContext context, WidgetRef ref, Drawing? drawing) async {
    // Lu avant toute navigation : `ref` n'est plus utilisable si la page se ferme pendant l'édition.
    final drawingControl = ref.read(createFormNotifierProvider.notifier).drawingControl;
    final draft = await ref.read(drawingDraftNotifierProvider.future);
    if (!context.mounted) {
      return;
    }
    final start = draft ?? drawing ?? await context.push<Drawing>(drawingFormatPath);
    if (start == null || !context.mounted) {
      return;
    }
    final edited = await context.push<Drawing>(drawingEditorPath, extra: start);
    if (edited == null || !context.mounted) {
      return;
    }
    drawingControl
      ..value = edited
      ..markAsTouched();
  }
}
