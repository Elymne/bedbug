import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/features/content/domain/extensions/drawing_dimensions_extension.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Icône de chaque orientation de la surface.
const Map<DrawingOrientation, IconData> _kOrientationIcons = {
  DrawingOrientation.landscape: Icons.crop_landscape,
  DrawingOrientation.portrait: Icons.crop_portrait,
};

/// Page de choix de la surface d'un nouveau dessin : sa taille et son orientation.
///
/// Passage obligé avant l'éditeur : la surface fixe le repère de tous les
/// traits, elle ne peut plus changer une fois le dessin commencé. Retourne à
/// la page qui l'a ouverte (`context.pop`) un dessin vide à la surface
/// choisie, ou rien si l'utilisateur ferme la page.
class DrawingFormatScreen extends ConsumerStatefulWidget {
  /// Crée un [DrawingFormatScreen].
  const DrawingFormatScreen({super.key});

  @override
  ConsumerState<DrawingFormatScreen> createState() => _State();
}

class _State extends ConsumerState<DrawingFormatScreen> {
  /// Taille choisie pour la surface.
  late final _sizeControl = FormControl<DrawingSize>(value: DrawingSize.medium);

  /// Orientation choisie pour la surface.
  late final _orientationControl = FormControl<DrawingOrientation>(value: DrawingOrientation.landscape);

  /// Formulaire du choix de la surface.
  late final FormGroup _form = FormGroup({'size': _sizeControl, 'orientation': _orientationControl});

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    final sizeLabels = {
      DrawingSize.small: l10n.drawingSurfaceSmall,
      DrawingSize.medium: l10n.drawingSurfaceMedium,
      DrawingSize.large: l10n.drawingSurfaceLarge,
    };
    final orientationLabels = {
      DrawingOrientation.landscape: l10n.drawingOrientationLandscape,
      DrawingOrientation.portrait: l10n.drawingOrientationPortrait,
    };

    return Scaffold(
      body: SafeArea(
        child: ReactiveForm(
          formGroup: _form,
          child: ReactiveFormConsumer(
            builder: (context, form, _) {
              final surface = _surface();
              return Padding(
                padding: const EdgeInsets.all(AppValues.baseMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    const Align(alignment: AlignmentDirectional.centerStart, child: AppCloseButton()),
                    Text(
                      l10n.drawingFormatTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Aperçu des proportions choisies, à la place que lui laisse l'écran.
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: surface.width / surface.height,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${surface.width} × ${surface.height}',
                                style: const TextStyle(color: AppColors.disabled),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(l10n.drawingFormatSizeLabel, textAlign: TextAlign.center),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        for (final size in DrawingSize.values)
                          ChoiceChip(
                            label: Text(sizeLabels[size]!),
                            selected: size == _sizeControl.value,
                            onSelected: (_) => _sizeControl.value = size,
                          ),
                      ],
                    ),
                    Text(l10n.drawingFormatOrientationLabel, textAlign: TextAlign.center),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        for (final orientation in DrawingOrientation.values)
                          ChoiceChip(
                            avatar: Icon(_kOrientationIcons[orientation]),
                            label: Text(orientationLabels[orientation]!),
                            selected: orientation == _orientationControl.value,
                            onSelected: (_) => _orientationControl.value = orientation,
                          ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppGradientButton(onTap: () => context.pop(surface), child: Text(l10n.drawingFormatStart)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Retourne un dessin vide à la surface choisie.
  Drawing _surface() {
    return Drawing(
      size: _sizeControl.value ?? DrawingSize.medium,
      orientation: _orientationControl.value ?? DrawingOrientation.landscape,
      palette: defaultDrawingPalette,
      operations: const [],
    );
  }
}
