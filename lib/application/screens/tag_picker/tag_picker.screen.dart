import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Opacité du fond d'une tuile de tag non sélectionné.
const double _kIdleBackgroundOpacity = 0.08;

/// Opacité du fond d'une tuile de tag sélectionné.
const double _kSelectedBackgroundOpacity = 0.28;

/// Opacité de la bordure d'une tuile de tag sélectionné.
const double _kSelectedBorderOpacity = 0.6;

/// Page listant tout le catalogue [Tag], pour en sélectionner plusieurs.
///
/// Une page plutôt qu'un nuage de tags dans le formulaire : le catalogue grandit, et chaque tag y dispose d'une ligne
/// entière teintée de sa couleur, plus lisible qu'une pastille. Un tap ajoute ou retire le tag ; le retour (bouton de
/// l'en-tête ou geste système) ferme la page et renvoie la sélection à l'appelant via `context.pop`.
class TagPickerScreen extends ConsumerStatefulWidget {
  /// Crée un [TagPickerScreen].
  ///
  /// - [selectedTags] : tags déjà sélectionnés à l'ouverture.
  const TagPickerScreen({super.key, required this.selectedTags});

  /// Tags déjà sélectionnés à l'ouverture.
  final List<Tag> selectedTags;

  @override
  ConsumerState<TagPickerScreen> createState() => _State();
}

class _State extends ConsumerState<TagPickerScreen> {
  /// Contrôle des tags sélectionnés sur la page.
  late final _tagsControl = FormControl<List<Tag>>(value: widget.selectedTags);

  /// Formulaire de la page.
  late final FormGroup _form = FormGroup({'tags': _tagsControl});

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le retour système doit renvoyer la sélection comme le bouton de l'en-tête : sans cela il renverrait `null` et
    // les choix faits sur la page seraient perdus.
    return PopScope<List<Tag>>(
      canPop: false,
      onPopInvokedWithResult: (isPopped, result) {
        if (isPopped) {
          return;
        }
        context.pop(_tagsControl.value);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(title: context.loc.tagPickerTitle, onBack: () => context.pop(_tagsControl.value)),
              Expanded(
                child: ReactiveValueListenableBuilder<List<Tag>>(
                  formControl: _tagsControl,
                  builder: (context, control, child) {
                    final selectedTags = control.value ?? const [];
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppValues.baseMargin,
                        0,
                        AppValues.baseMargin,
                        AppValues.baseMargin,
                      ),
                      itemCount: Tag.values.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tag = Tag.values[index];
                        final isSelected = selectedTags.contains(tag);
                        final colors = tag.flutterColors;
                        final gradient = LinearGradient(
                          colors: colors.length == 1 ? [colors.first, colors.first] : colors,
                        );
                        final borderRadius = BorderRadius.circular(AppValues.fieldRadius);

                        return Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: borderRadius,
                            onTap: () => _toggleTag(tag),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: borderRadius,
                                gradient: gradient.scale(
                                  isSelected ? _kSelectedBackgroundOpacity : _kIdleBackgroundOpacity,
                                ),
                                // Bordure toujours présente, transparente hors sélection : la tuile ne bouge pas
                                // d'un pixel quand on la coche.
                                border: Border.all(
                                  color: colors.first.withValues(alpha: isSelected ? _kSelectedBorderOpacity : 0),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ShaderMask(
                                      shaderCallback: gradient.createShader,
                                      blendMode: BlendMode.srcIn,
                                      child: Text(
                                        tag.text,
                                        style: const TextStyle(
                                          color: AppColors.onDark,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isSelected) AppIcon(AppIcons.check, color: colors.last),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ajoute ou retire [tag] de la sélection.
  ///
  /// Relit la sélection au moment de l'appel plutôt que celle affichée au dernier rebuild : deux taps rapprochés
  /// écraseraient sinon la sélection précédente au lieu de s'accumuler. L'ordre de la sélection suit celui des taps.
  ///
  /// - [tag] : tag touché.
  void _toggleTag(Tag tag) {
    final selectedTags = _tagsControl.value ?? const [];
    if (selectedTags.contains(tag)) {
      _tagsControl.value = selectedTags.where((selectedTag) => selectedTag != tag).toList();
      return;
    }
    _tagsControl.value = [...selectedTags, tag];
  }
}
