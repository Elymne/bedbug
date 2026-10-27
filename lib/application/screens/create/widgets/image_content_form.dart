import 'dart:io';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Côté d'une miniature d'image choisie, en pixels logiques.
const double _thumbnailSize = 96;

/// Champs de création d'un contenu image : images choisies, titre et description.
///
/// Les contrôles restent portés par la page de création, qui en a besoin pour
/// valider et construire le contenu à l'enregistrement. Les images choisies
/// sont écrites dans [imagesControl] : la page les lit et les valide comme
/// n'importe quel autre champ, sans état parallèle à synchroniser.
///
/// L'ouverture du sélecteur d'images est déléguée à la page ([onAddImages]),
/// qui l'ouvre aussi d'elle-même dès que le type image est choisi.
class ImageContentForm extends ConsumerWidget {
  /// Crée un [ImageContentForm].
  ///
  /// - [imagesControl] : contrôle portant les images choisies dans la galerie.
  /// - [titleControl] : contrôle du titre du contenu.
  /// - [bodyControl] : contrôle de la description optionnelle.
  /// - [onAddImages] : callback ouvrant le sélecteur pour ajouter des images.
  const ImageContentForm({
    super.key,
    required this.imagesControl,
    required this.titleControl,
    required this.bodyControl,
    required this.onAddImages,
  });

  /// Contrôle portant les images choisies dans la galerie, dans l'ordre d'affichage.
  final FormControl<List<XFile>> imagesControl;

  /// Contrôle du titre du contenu.
  final FormControl<String> titleControl;

  /// Contrôle de la description optionnelle.
  final FormControl<String> bodyControl;

  /// Callback ouvrant le sélecteur pour ajouter des images.
  final VoidCallback onAddImages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        StreamBuilder<List<XFile>?>(
          stream: imagesControl.valueChanges,
          initialData: imagesControl.value,
          builder: (context, _) {
            final images = imagesControl.value ?? const <XFile>[];
            if (images.isEmpty) {
              return Center(
                child: ElevatedButton.icon(
                  onPressed: onAddImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.createImagePickLabel),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 8,
                    children: [
                      for (final (index, image) in images.indexed)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(image.path),
                                width: _thumbnailSize,
                                height: _thumbnailSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                            PositionedDirectional(
                              top: 4,
                              end: 4,
                              child: GestureDetector(
                                onTap: () => imagesControl.value = [...images]..removeAt(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: AppColors.onDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (images.length < maxImagesPerContent)
                        InkWell(
                          onTap: onAddImages,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: _thumbnailSize,
                            height: _thumbnailSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.onLighter),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(l10n.createImageCount(images.length, maxImagesPerContent)),
              ],
            );
          },
        ),
        ReactiveTextField<String>(
          formControl: titleControl,
          textCapitalization: TextCapitalization.sentences,
          validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
          decoration: InputDecoration(labelText: l10n.createTextTitleLabel),
        ),
        ReactiveTextField<String>(
          formControl: bodyControl,
          textCapitalization: TextCapitalization.sentences,
          // Démarre sur une ligne et grandit avec le texte : la barre du bas
          // descend à chaque nouvelle ligne (c'est la page qui défile).
          minLines: 1,
          maxLines: null,
          decoration: InputDecoration(labelText: l10n.createImageBodyLabel),
        ),
      ],
    );
  }
}
