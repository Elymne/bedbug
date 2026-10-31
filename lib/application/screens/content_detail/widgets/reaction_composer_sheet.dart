import 'package:bedbug/application/notifiers/save_reaction_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/application/widgets/reactions/app_reaction_bubble.dart';
import 'package:bedbug/application/widgets/signature/app_ghost_color_selector.dart';
import 'package:bedbug/application/widgets/signature/app_ghost_speed_slider.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/application/widgets/texts/app_text_font_selector.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Feuille de saisie de la réaction de l'utilisateur sur un contenu : bedbug, couleur et intensité de son ghost, bulle de texte.
///
/// Le bedbug se choisit uniquement dans le catalogue des signatures. Un
/// aperçu montre la réaction telle qu'elle sera affichée. Se ferme une fois
/// la réaction enregistrée. À afficher via [show].
class ReactionComposerSheet extends ConsumerStatefulWidget {
  /// Crée un [ReactionComposerSheet].
  ///
  /// - [contentId] : identifiant du contenu auquel réagir.
  /// - [localSignature] : signature de l'utilisateur, dont le bedbug et le ghost sont proposés par défaut.
  /// - [ownReaction] : réaction actuelle de l'utilisateur, qui préremplit le formulaire, `null` s'il n'a pas encore réagi.
  const ReactionComposerSheet({super.key, required this.contentId, required this.localSignature, this.ownReaction});

  /// Identifiant du contenu auquel réagir.
  final String contentId;

  /// Signature de l'utilisateur du téléphone.
  final Signature localSignature;

  /// Réaction actuelle de l'utilisateur sur ce contenu, `null` s'il n'a pas encore réagi.
  final Reaction? ownReaction;

  /// Affiche la feuille de saisie de réaction.
  ///
  /// - [context] : contexte depuis lequel ouvrir la feuille.
  /// - [contentId] : identifiant du contenu auquel réagir.
  /// - [localSignature] : signature de l'utilisateur du téléphone.
  /// - [ownReaction] : réaction actuelle de l'utilisateur, `null` s'il n'a pas encore réagi.
  static Future<void> show(
    BuildContext context, {
    required String contentId,
    required Signature localSignature,
    Reaction? ownReaction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) {
        return ReactionComposerSheet(contentId: contentId, localSignature: localSignature, ownReaction: ownReaction);
      },
    );
  }

  @override
  ConsumerState<ReactionComposerSheet> createState() => _State();
}

class _State extends ConsumerState<ReactionComposerSheet> {
  /// Contrôle du bedbug choisi, par défaut celui de la réaction actuelle ou de la signature de l'utilisateur.
  late final _avatarTextControl = FormControl<String>(
    value: widget.ownReaction?.avatarText ?? widget.localSignature.avatarText,
    validators: [AppValidators.required, AppValidators.avatarText],
  );

  /// Contrôle de la bulle de texte, obligatoire.
  late final _bubbleTextControl = FormControl<String>(
    value: widget.ownReaction?.bubbleText,
    validators: [AppValidators.required, AppValidators.reactionBubble],
  );

  /// Contrôle de la couleur du ghost, par défaut celle de la réaction actuelle ou de la signature de l'utilisateur.
  late final _colorControl = FormControl<Color>(value: _initialColor());

  /// Contrôle de l'intensité du ghost, par défaut celle de la réaction actuelle ou de la signature de l'utilisateur.
  late final _ghostSpeedControl = FormControl<double>(
    value: widget.ownReaction?.ghostSpeed ?? widget.localSignature.ghostSpeed,
  );

  /// Contrôle de la police de la bulle, par défaut celle de la réaction actuelle.
  late final _bubbleFontControl = FormControl<TextFont>(value: widget.ownReaction?.bubbleFont ?? TextFont.standard);

  /// Formulaire de la réaction.
  late final FormGroup _form = FormGroup({
    'avatarText': _avatarTextControl,
    'bubbleText': _bubbleTextControl,
    'bubbleFont': _bubbleFontControl,
    'color': _colorControl,
    'ghostSpeed': _ghostSpeedControl,
  });

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    final saveReactionNotifierWatcher = ref.watch(saveReactionNotifierProvider);

    return Padding(
      // Remonte la feuille au-dessus du clavier pendant la saisie de la bulle.
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
                l10n.reactionComposerTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onLight),
              ),
              StreamBuilder<Map<String, Object?>?>(
                stream: _form.valueChanges,
                initialData: _form.value,
                builder: (context, _) {
                  return Center(
                    child: AppReactionBubble(
                      avatarText: _avatarTextControl.value ?? widget.localSignature.avatarText,
                      bubbleText: _bubbleTextControl.value,
                      bubbleFont: _bubbleFontControl.value ?? TextFont.standard,
                      ghostColor: _colorControl.value ?? AppColors.primary,
                      ghostSpeed: _ghostSpeedControl.value ?? defaultGhostSpeed,
                      fontSize: 32,
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                onPressed: _pickBedbug,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onLight,
                  side: const BorderSide(color: AppColors.onLight),
                ),
                icon: const Icon(Icons.grid_view_rounded, color: AppColors.onLight),
                label: Text(l10n.reactionChangeBedbugButton),
              ),
              Text(l10n.settingsColorLabel),
              AppGhostColorSelector(control: _colorControl),
              Text(l10n.settingsGhostSpeedLabel),
              AppGhostSpeedSlider(formControl: _ghostSpeedControl),
              ReactiveTextField<String>(
                formControl: _bubbleTextControl,
                textCapitalization: TextCapitalization.sentences,
                maxLength: maxReactionBubbleLength,
                maxLines: null,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.reactionBubbleLabel),
                validationMessages: {
                  ValidationMessage.required: (_) => l10n.createRequiredFieldError,
                  'reactionBubble': (_) => l10n.reactionBubbleError(maxReactionBubbleLength),
                },
              ),
              Text(l10n.textFontLabel),
              AppTextFontSelector(control: _bubbleFontControl),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppGradientButton(
                  isLoading: saveReactionNotifierWatcher.isLoading,
                  onTap: _onSave,
                  child: Text(l10n.reactionSaveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Couleur initiale du ghost : celle de la réaction actuelle, sinon celle de la signature, sinon la couleur primaire.
  Color _initialColor() {
    final colorArgb = widget.ownReaction?.colorArgb ?? widget.localSignature.colorArgb;
    if (colorArgb == null) {
      return AppColors.primary;
    }
    return Color(colorArgb);
  }

  /// Ouvre le catalogue des bedbugs et applique celui choisi.
  ///
  /// Revenir sans choisir laisse le bedbug actuel en place.
  Future<void> _pickBedbug() async {
    final kaomoji = await context.push<String>(reactionPickerPath);
    if (kaomoji == null) {
      return;
    }
    _avatarTextControl.value = kaomoji;
  }

  /// Valide le formulaire, enregistre la réaction puis ferme la feuille.
  ///
  /// En cas d'échec, la feuille reste ouverte et l'erreur est affichée.
  Future<void> _onSave() async {
    if (!_form.valid) {
      _form.markAllAsTouched();
      return;
    }

    final failureMessage = await ref
        .read(saveReactionNotifierProvider.notifier)
        .save(
          contentId: widget.contentId,
          avatarText: _avatarTextControl.value!,
          bubbleText: _bubbleTextControl.value!,
          colorArgb: (_colorControl.value ?? AppColors.primary).toARGB32(),
          ghostSpeed: _ghostSpeedControl.value ?? defaultGhostSpeed,
          bubbleFont: _bubbleFontControl.value ?? TextFont.standard,
          previousReaction: widget.ownReaction,
        );
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
