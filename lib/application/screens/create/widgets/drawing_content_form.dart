import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/notifiers/drawing_draft_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/drawing/app_drawing_image.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champs de création d'un contenu dessiné : le titre, et le dessin fait dans l'éditeur.
///
/// Les contrôles restent portés par la page de création, qui en a besoin pour
/// valider et construire le contenu à l'enregistrement : ce widget se contente
/// de les afficher, et d'ouvrir l'éditeur.
class DrawingContentForm extends ConsumerWidget {
  /// Crée un [DrawingContentForm].
  ///
  /// - [drawingControl] : contrôle du dessin, `null` tant que rien n'a été dessiné.
  /// - [titleControl] : contrôle du titre du contenu.
  const DrawingContentForm({super.key, required this.drawingControl, required this.titleControl});

  /// Contrôle du dessin, `null` tant que rien n'a été dessiné.
  final FormControl<Drawing> drawingControl;

  /// Contrôle du titre du contenu.
  final FormControl<String> titleControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        ReactiveTextField<String>(
          formControl: titleControl,
          textCapitalization: TextCapitalization.sentences,
          validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
          decoration: InputDecoration(labelText: l10n.createTextTitleLabel),
        ),
        ReactiveValueListenableBuilder<Drawing>(
          formControl: drawingControl,
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
                OutlinedButton.icon(
                  onPressed: () => _openEditor(context, ref, drawing),
                  icon: const Icon(Icons.brush_outlined),
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
  /// - [ref] : accès au brouillon.
  /// - [drawing] : dessin à reprendre, `null` pour en commencer un.
  Future<void> _openEditor(BuildContext context, WidgetRef ref, Drawing? drawing) async {
    final draft = await ref.read(drawingDraftNotifierProvider.future);
    if (!context.mounted) {
      return;
    }
    final start = draft ?? drawing ?? await context.push<Drawing>(drawingFormatPath);
    if (start == null || !context.mounted) {
      return;
    }
    final edited = await context.push<Drawing>(drawingEditorPath, extra: start);
    if (edited == null) {
      return;
    }
    drawingControl
      ..value = edited
      ..markAsTouched();
  }
}
