import 'dart:io';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Champs de création d'un contenu image : choix de l'image, titre et description.
///
/// Les contrôles restent portés par la page de création, qui en a besoin pour
/// valider et construire le contenu à l'enregistrement. L'image choisie est
/// écrite dans [imageControl] : la page la lit et la valide comme n'importe
/// quel autre champ, sans état parallèle à synchroniser.
class ImageContentForm extends ConsumerWidget {
  /// Crée un [ImageContentForm].
  ///
  /// - [imageControl] : contrôle portant l'image choisie dans la galerie.
  /// - [titleControl] : contrôle du titre du contenu.
  /// - [bodyControl] : contrôle de la description optionnelle.
  const ImageContentForm({
    super.key,
    required this.imageControl,
    required this.titleControl,
    required this.bodyControl,
  });

  /// Contrôle portant l'image choisie dans la galerie.
  final FormControl<XFile> imageControl;

  /// Contrôle du titre du contenu.
  final FormControl<String> titleControl;

  /// Contrôle de la description optionnelle.
  final FormControl<String> bodyControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      spacing: 16,
      children: [
        StreamBuilder<XFile?>(
          stream: imageControl.valueChanges,
          initialData: imageControl.value,
          builder: (context, _) {
            final image = imageControl.value;
            if (image == null) {
              return const SizedBox.shrink();
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(image.path), width: double.infinity, fit: BoxFit.cover),
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_outlined),
          label: Text(l10n.createImagePickLabel),
        ),
        ReactiveTextField<String>(
          formControl: titleControl,
          decoration: InputDecoration(labelText: l10n.createImageTitleLabel),
        ),
        ReactiveTextField<String>(
          formControl: bodyControl,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.createImageBodyLabel),
        ),
      ],
    );
  }

  /// Ouvre le sélecteur d'image de la galerie et enregistre le choix dans [imageControl].
  ///
  /// Une annulation laisse l'image précédente en place plutôt que de vider le
  /// champ, pour qu'un aller-retour dans la galerie ne fasse rien perdre.
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    imageControl.value = image;
  }
}
