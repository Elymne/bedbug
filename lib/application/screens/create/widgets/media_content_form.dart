import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Côté de la vignette d'un média ajouté.
const double _kThumbnailSize = 56;

/// Champs de création d'un contenu média : les adresses des médias, puis le titre et la description.
///
/// Les médias ne sont plus envoyés depuis le téléphone : l'auteur les
/// héberge sur un site reconnu et colle ici leur adresse. Chaque adresse est
/// vérifiée avant d'être ajoutée, et affichée en vignette comme la verront
/// les autres, selon ses propres listes de domaines.
///
/// Les contrôles des médias, du titre et de la description restent portés
/// par la page de création, qui en a besoin pour valider et construire le
/// contenu à l'enregistrement.
class MediaContentForm extends ConsumerStatefulWidget {
  /// Crée un [MediaContentForm].
  ///
  /// - [mediaUrlsControl] : contrôle portant les adresses des médias ajoutés, dans l'ordre d'affichage.
  /// - [titleControl] : contrôle du titre du contenu.
  /// - [bodyControl] : contrôle de la description optionnelle.
  const MediaContentForm({
    super.key,
    required this.mediaUrlsControl,
    required this.titleControl,
    required this.bodyControl,
  });

  /// Contrôle portant les adresses des médias ajoutés, dans l'ordre d'affichage.
  final FormControl<List<String>> mediaUrlsControl;

  /// Contrôle du titre du contenu.
  final FormControl<String> titleControl;

  /// Contrôle de la description optionnelle.
  final FormControl<String> bodyControl;

  @override
  ConsumerState<MediaContentForm> createState() => _State();
}

class _State extends ConsumerState<MediaContentForm> {
  /// Contrôle de l'adresse en cours de saisie, avant son ajout à la liste.
  late final _urlInputControl = FormControl<String>(validators: [AppValidators.safeUrl]);

  @override
  void dispose() {
    _urlInputControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        StreamBuilder<List<String>?>(
          stream: widget.mediaUrlsControl.valueChanges,
          initialData: widget.mediaUrlsControl.value,
          builder: (context, _) {
            final mediaUrls = widget.mediaUrlsControl.value ?? const <String>[];
            final isFull = mediaUrls.length >= maxMediaPerContent;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                ReactiveTextField<String>(
                  formControl: _urlInputControl,
                  readOnly: isFull,
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _addUrl(),
                  validationMessages: {'safeUrl': (_) => l10n.urlInvalidError},
                  decoration: InputDecoration(
                    labelText: l10n.createMediaUrlLabel,
                    helperText: l10n.createMediaCount(mediaUrls.length, maxMediaPerContent),
                    suffixIcon: IconButton(
                      onPressed: isFull ? null : _addUrl,
                      tooltip: l10n.createMediaAddButton,
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    ),
                  ),
                ),
                ReactiveStatusListenableBuilder(
                  formControl: widget.mediaUrlsControl,
                  builder: (context, control, _) {
                    if (!control.invalid || !control.touched) {
                      return const SizedBox.shrink();
                    }
                    return Text(l10n.createMediaRequiredError, style: const TextStyle(color: AppColors.failure));
                  },
                ),
                for (final (index, url) in mediaUrls.indexed)
                  Row(
                    spacing: 12,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox.square(
                          dimension: _kThumbnailSize,
                          child: AppRemoteMedia(media: ContentMedia.fromUrl(url)),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          SafeUrl.tryParse(url)?.host ?? url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.onLight),
                        ),
                      ),
                      IconButton(
                        onPressed: () => widget.mediaUrlsControl.value = [...mediaUrls]..removeAt(index),
                        tooltip: l10n.settingsSocialRemove,
                        icon: const Icon(Icons.close_rounded, color: AppColors.onLight),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
        ReactiveTextField<String>(
          formControl: widget.titleControl,
          textCapitalization: TextCapitalization.sentences,
          validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
          decoration: InputDecoration(labelText: l10n.createTextTitleLabel),
        ),
        ReactiveTextField<String>(
          formControl: widget.bodyControl,
          textCapitalization: TextCapitalization.sentences,
          maxLines: null,
          decoration: InputDecoration(labelText: l10n.createImageBodyLabel),
        ),
      ],
    );
  }

  /// Vérifie l'adresse saisie et l'ajoute à la suite des médias, puis vide le champ.
  ///
  /// Une adresse déjà ajoutée n'est pas dupliquée. Une adresse refusée reste
  /// dans le champ, avec son message d'erreur, pour pouvoir la corriger.
  void _addUrl() {
    final url = _urlInputControl.value?.trim() ?? '';
    if (url.isEmpty) {
      return;
    }
    if (!_urlInputControl.valid) {
      _urlInputControl.markAsTouched();
      return;
    }
    final mediaUrls = widget.mediaUrlsControl.value ?? const <String>[];
    if (!mediaUrls.contains(url) && mediaUrls.length < maxMediaPerContent) {
      widget.mediaUrlsControl.value = [...mediaUrls, url];
    }
    _urlInputControl.reset();
  }
}
