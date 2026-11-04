import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.widget.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Côté de la vignette d'un média ajouté.
const double _kThumbnailSize = 56;

/// Champs de création d'un contenu média : les adresses des médias, puis le titre et la description.
///
/// Les médias ne sont plus envoyés depuis le téléphone : l'auteur les héberge sur un site reconnu et colle ici leur
/// adresse. Chaque adresse est vérifiée avant d'être ajoutée, et affichée en vignette comme la verront les autres,
/// selon ses propres listes de domaines.
///
/// Les contrôles et l'ajout ou le retrait d'une adresse sont portés par le [CreateFormNotifier] : ce widget se contente
/// de les afficher.
class MediaContentForm extends ConsumerWidget {
  /// Crée un [MediaContentForm].
  const MediaContentForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        ReactiveValueListenableBuilder<List<String>>(
          formControl: ref.read(createFormNotifierProvider.notifier).mediaUrlsControl,
          builder: (context, control, child) {
            final mediaUrls = control.value ?? const <String>[];
            final isFull = mediaUrls.length >= maxMediaPerContent;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                AppFieldFocusPulse(
                  child: ReactiveTextField<String>(
                    formControl: ref.read(createFormNotifierProvider.notifier).mediaUrlInputControl,
                    readOnly: isFull,
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => ref.read(createFormNotifierProvider.notifier).addMediaUrl(),
                    validationMessages: {'safeUrl': (_) => l10n.urlInvalidError},
                    decoration: InputDecoration(
                      labelText: l10n.createMediaUrlLabel,
                      hintText: l10n.createMediaUrlHint,
                      helperText: l10n.createMediaCount(mediaUrls.length, maxMediaPerContent),
                      suffixIcon: IconButton(
                        onPressed: isFull ? null : ref.read(createFormNotifierProvider.notifier).addMediaUrl,
                        tooltip: l10n.createMediaAddButton,
                        icon: const AppIcon(AppIcons.addCircle, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                ReactiveStatusListenableBuilder(
                  formControl: control,
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
                          SafeUrl.parse(url)?.host ?? url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.onLight),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(createFormNotifierProvider.notifier).removeMediaUrl(index),
                        tooltip: l10n.settingsSocialRemove,
                        icon: const AppIcon(AppIcons.close, color: AppColors.onLight),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: ref.read(createFormNotifierProvider.notifier).mediaTitleControl,
            textCapitalization: TextCapitalization.sentences,
            validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
            decoration: InputDecoration(labelText: l10n.createTextTitleLabel, hintText: l10n.createTitleHint),
          ),
        ),
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: ref.read(createFormNotifierProvider.notifier).mediaBodyControl,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            decoration: InputDecoration(labelText: l10n.createImageBodyLabel, hintText: l10n.createImageBodyHint),
          ),
        ),
      ],
    );
  }
}
