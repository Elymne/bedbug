import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/content_type_selector/content_type_selector.widget.dart';
import 'package:bedbug/application/screens/create/create_form/create_form.notifier.dart';
import 'package:bedbug/application/screens/create/create_publish_button/create_publish_button.widget.dart';
import 'package:bedbug/application/screens/create/drawing_content_form/drawing_content_form.widget.dart';
import 'package:bedbug/application/screens/create/link_content_form/link_content_form.widget.dart';
import 'package:bedbug/application/screens/create/media_content_form/media_content_form.widget.dart';
import 'package:bedbug/application/screens/create/tag_select_box/tag_select_box.widget.dart';
import 'package:bedbug/application/screens/create/text_content_form/text_content_form.widget.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.widget.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/content_type.enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Formulaire de création de contenu, avec sa barre du haut (fermer, publier).
///
/// Seul widget de la page à observer le [CreateFormNotifier] : il attend que le formulaire soit prêt (le réglage
/// « anonyme par défaut » lu), puis le garde en vie tant qu'il est affiché. Les parties qui dépendent des valeurs
/// saisies (type choisi, champs du type) se reconstruisent d'elles-mêmes en écoutant leurs contrôles.
class CreateForm extends ConsumerWidget {
  /// Crée un [CreateForm].
  const CreateForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createFormNotifierWatcher = ref.watch(createFormNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return createFormNotifierWatcher.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (_) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                  child: Row(children: [AppCloseButton(), Spacer(), CreatePublishButton()]),
                ),
                // Tout le formulaire défile sous la barre du haut, qui garde fermer et publier à portée de main.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppValues.baseMargin,
                      0,
                      AppValues.baseMargin,
                      AppValues.baseMargin * 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Le verrouillage dépend de toutes les valeurs saisies : le sélecteur écoute tout le formulaire.
                        ReactiveValueListenableBuilder<Map<String, Object?>>(
                          formControl: ref.read(createFormNotifierProvider.notifier).form,
                          builder: (context, control, child) {
                            return ContentTypeSelector(
                              selectedType: ref.read(createFormNotifierProvider.notifier).selectedType,
                              isLocked: ref.read(createFormNotifierProvider.notifier).isTypeLocked,
                              onTypeSelected: (type) {
                                ref.read(createFormNotifierProvider.notifier).typeControl.value = type;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            AppFieldFocusPulse(
                              child: ReactiveTextField<String>(
                                formControl: ref.read(createFormNotifierProvider.notifier).flairControl,
                                maxLength: maxFlairLength,
                                validationMessages: {'required': (_) => l10n.createFlairRequiredError},
                                decoration: InputDecoration(
                                  labelText: l10n.createFlairLabel,
                                  hintText: l10n.createFlairHint,
                                  prefixText: flairPrefix,
                                  prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const TagSelectBox(),
                            ReactiveCheckboxListTile(
                              formControl: ref.read(createFormNotifierProvider.notifier).isAnonymousControl,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(l10n.createAnonymousLabel),
                              subtitle: Text(l10n.createAnonymousDescription),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ReactiveValueListenableBuilder<ContentType>(
                          formControl: ref.read(createFormNotifierProvider.notifier).typeControl,
                          builder: (context, control, child) {
                            return switch (control.value ?? ContentType.text) {
                              ContentType.text => const TextContentForm(),
                              ContentType.media => const MediaContentForm(),
                              ContentType.link => const LinkContentForm(),
                              ContentType.drawing => const DrawingContentForm(),
                            };
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
