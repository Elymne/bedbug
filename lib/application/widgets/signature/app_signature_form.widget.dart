import 'package:bedbug/application/formatters/avatar_text_input_formatter.dart';
import 'package:bedbug/application/notifiers/local_signature.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/validators/avatar_text.validator.dart';
import 'package:bedbug/application/validators/not_empty.validator.dart';
import 'package:bedbug/application/validators/pseudo.validator.dart';
import 'package:bedbug/application/validators/signature_bio.validator.dart';
import 'package:bedbug/application/widgets/buttons/app_form_submit_button.widget.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.widget.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/scroll/app_sticky_top.widget.dart';
import 'package:bedbug/application/widgets/signature/app_avatar_frame_speed_slider.widget.dart';
import 'package:bedbug/application/widgets/signature/app_ghost_color_selector.widget.dart';
import 'package:bedbug/application/widgets/signature/app_ghost_speed_slider.widget.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.widget.dart';
import 'package:bedbug/application/widgets/signature/app_signature_bio.widget.dart';
import 'package:bedbug/application/widgets/signature/app_signature_form.notifier.dart';
import 'package:bedbug/application/widgets/signature/social_links_editor.widget.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.widget.dart';
import 'package:bedbug/application/widgets/texts/app_text_font_selector.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Longueur maximale de l'icône texte.
const int _kAvatarMaxLength = 16;

/// Formulaire de configuration du profil de l'utilisateur du téléphone.
///
/// Affiche en tête un aperçu en direct de l'icône (effet ghost dans la
/// couleur choisie), du pseudo et de la description, qui reste visible au
/// défilement pour montrer l'effet de chaque réglage. Viennent ensuite les champs : pseudo,
/// description, icône texte
/// (écrite à la main ou choisie dans le catalogue), couleur et liens vers les
/// réseaux.
///
/// Partagé entre la création de la signature et les paramètres : seuls le
/// libellé du bouton et la suite d'un enregistrement réussi diffèrent.
class AppSignatureForm extends ConsumerStatefulWidget {
  /// Crée un [AppSignatureForm].
  ///
  /// - [signature] : profil enregistré servant de valeurs initiales, `null` s'il n'a jamais été configuré.
  /// - [submitLabel] : libellé du bouton d'enregistrement.
  /// - [onSaved] : appelé une fois le profil enregistré et le profil chargé mis à jour.
  const AppSignatureForm({super.key, required this.signature, required this.submitLabel, required this.onSaved});

  /// Profil enregistré servant de valeurs initiales.
  final Signature? signature;

  /// Libellé du bouton d'enregistrement.
  final String submitLabel;

  /// Appelé une fois le profil enregistré et le profil chargé mis à jour.
  final VoidCallback onSaved;

  @override
  ConsumerState<AppSignatureForm> createState() => _State();
}

class _State extends ConsumerState<AppSignatureForm> {
  /// Contrôle du pseudo.
  late final _pseudoControl = FormControl<String>(
    value: widget.signature?.pseudo,
    validators: [const NotEmptyValidator(), const PseudoValidator()],
  );

  /// Contrôle de la courte description.
  late final _bioControl = FormControl<String>(
    value: widget.signature?.bio,
    validators: [const SignatureBioValidator()],
  );

  /// Contrôle de la police de la description.
  late final _bioFontControl = FormControl<TextFont>(value: widget.signature?.bioFont ?? TextFont.standard);

  /// Contrôle du bedbug saisi : une seule frame, la première de l'animation quand elle vient du catalogue.
  late final _avatarTextControl = FormControl<String>(
    value: widget.signature?.avatarFrames.first ?? defaultSignatureAvatarText,
    validators: [const NotEmptyValidator(), const AvatarTextValidator()],
  );

  /// Contrôle des frames du bedbug animé choisi dans le catalogue, `null` pour un bedbug fixe.
  ///
  /// La saisie ne permet qu'une frame : une animation ne vient que du catalogue. Elle reste choisie tant que le champ
  /// affiche sa première frame ; dès que l'utilisateur tape autre chose, son bedbug redevient fixe (voir
  /// [_avatarFrames]).
  late final _catalogFramesControl = FormControl<List<String>>(
    value: (widget.signature?.avatarFrames.length ?? 0) > 1 ? widget.signature!.avatarFrames : null,
  );

  /// Contrôle de la couleur de l'effet ghost.
  late final _colorControl = FormControl<Color>(value: _initialColor());

  /// Contrôle de la vitesse de l'effet ghost.
  late final _ghostSpeedControl = FormControl<double>(value: widget.signature?.ghostSpeed ?? defaultGhostSpeed);

  /// Contrôle de la vitesse de l'animation du bedbug.
  late final _avatarFrameSpeedControl = FormControl<double>(
    value: widget.signature?.avatarFrameSpeed ?? defaultAvatarFrameSpeed,
  );

  /// Contrôle des identifiants par réseau.
  late final _socialLinksControl = FormControl<Map<SocialNetwork, String>>(
    value: widget.signature?.socialLinks ?? const {},
  );

  /// Formulaire du profil.
  late final FormGroup _form = FormGroup({
    'pseudo': _pseudoControl,
    'bio': _bioControl,
    'bioFont': _bioFontControl,
    'avatarText': _avatarTextControl,
    'catalogFrames': _catalogFramesControl,
    'color': _colorControl,
    'ghostSpeed': _ghostSpeedControl,
    'avatarFrameSpeed': _avatarFrameSpeedControl,
    'socialLinks': _socialLinksControl,
  });

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    final appSignatureFormNotifierWatcher = ref.watch(appSignatureFormNotifierProvider);

    ref.listen(appSignatureFormNotifierProvider, (previous, next) {
      if (next.isLoading) return;
      final saveState = next.value;
      if (saveState == null) return;
      final savedSignature = saveState.savedSignature;
      if (savedSignature != null) {
        ref.read(localSignatureNotifierProvider.notifier).setSignature(savedSignature);
        widget.onSaved();
        return;
      }
      if (saveState.failureMessage != null) {
        AppSnackbar.showError(context, saveState.failureMessage!);
      }
    });

    // De bas en haut : l'aperçu, écrit en dernier, est dessiné par-dessus les champs qu'il recouvre en restant visible.
    return Column(
      verticalDirection: VerticalDirection.up,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            AppFieldFocusPulse(
              child: ReactiveTextField<String>(
                formControl: _pseudoControl,
                maxLength: maxPseudoLength,
                inputFormatters: [FilteringTextInputFormatter.allow(pseudoAllowedCharacter)],
                decoration: InputDecoration(
                  labelText: l10n.settingsPseudoLabel,
                  hintText: l10n.settingsPseudoHint,
                  prefixText: signaturePrefix,
                  prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => l10n.createRequiredFieldError,
                  'pseudo': (_) => l10n.settingsPseudoError,
                },
              ),
            ),
            AppFieldFocusPulse(
              child: ReactiveTextField<String>(
                formControl: _bioControl,
                textCapitalization: TextCapitalization.sentences,
                maxLength: maxSignatureBioLength,
                maxLines: null,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.settingsBioLabel, hintText: l10n.settingsBioHint),
                validationMessages: {'signatureBio': (_) => l10n.settingsBioError(maxSignatureBioLength)},
              ),
            ),
            AppTextFontSelector(control: _bioFontControl),
            AppFieldFocusPulse(
              child: ReactiveTextField<String>(
                formControl: _avatarTextControl,
                maxLength: _kAvatarMaxLength,
                inputFormatters: const [AvatarTextInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.settingsAvatarLabel,
                  hintText: defaultSignatureAvatarText,
                  suffixIcon: IconButton(
                    onPressed: _pickAvatarFromCatalog,
                    tooltip: l10n.settingsAvatarBrowse,
                    icon: const AppIcon(AppIcons.list, color: AppColors.primary),
                  ),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => l10n.createRequiredFieldError,
                  'avatarText': (_) => l10n.settingsAvatarError,
                },
              ),
            ),
            Text(l10n.settingsColorLabel),
            AppGhostColorSelector(control: _colorControl),
            Text(l10n.settingsGhostSpeedLabel),
            AppGhostSpeedSlider(formControl: _ghostSpeedControl),
            // Réglage réservé aux bedbugs animés : sans effet sur un bedbug d'une seule frame, il reste caché.
            StreamBuilder<Map<String, Object?>?>(
              stream: _form.valueChanges,
              initialData: _form.value,
              builder: (context, _) {
                if (_avatarFrames().length < 2) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    Text(l10n.settingsAvatarFrameSpeedLabel),
                    AppAvatarFrameSpeedSlider(formControl: _avatarFrameSpeedControl),
                  ],
                );
              },
            ),
            Text(l10n.settingsSocialLabel),
            StreamBuilder<Color?>(
              stream: _colorControl.valueChanges,
              initialData: _colorControl.value,
              builder: (context, _) {
                return SocialLinksEditor(
                  control: _socialLinksControl,
                  accentColor: _colorControl.value ?? AppColors.primary,
                );
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AppFormSubmitButton(
                form: _form,
                isLoading: appSignatureFormNotifierWatcher.isLoading,
                onTap: _onSave,
                child: Text(widget.submitLabel),
              ),
            ),
          ],
        ),
        AppStickyTop(
          child: StreamBuilder<Map<String, Object?>?>(
            stream: _form.valueChanges,
            initialData: _form.value,
            builder: (context, _) {
              final pseudo = _pseudoControl.value?.trim() ?? '';
              final bio = _bioControl.value?.trim() ?? '';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppValues.fieldRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  spacing: 8,
                  children: [
                    AppSignatureAvatar(
                      avatarFrames: _avatarFrames(),
                      ghostColor: _colorControl.value ?? AppColors.primary,
                      ghostSpeed: _ghostSpeedControl.value ?? defaultGhostSpeed,
                      avatarFrameSpeed: _avatarFrameSpeedControl.value ?? defaultAvatarFrameSpeed,
                    ),
                    AppPrefixedText(
                      prefix: signaturePrefix,
                      text: pseudo.isEmpty ? anonymousSignature.pseudo : pseudo,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onLight),
                    ),
                    if (bio.isNotEmpty) AppSignatureBio(bio: bio, font: _bioFontControl.value ?? TextFont.standard),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Couleur initiale du sélecteur : celle du profil enregistré, ou la couleur primaire de l'app.
  Color _initialColor() {
    final colorArgb = widget.signature?.colorArgb;
    if (colorArgb == null) {
      return AppColors.primary;
    }
    return Color(colorArgb);
  }

  /// Frames du bedbug à afficher et à enregistrer, déduites du champ et du choix fait dans le catalogue.
  ///
  /// L'animation du catalogue n'est gardée que si le champ affiche encore sa première frame : taper un autre bedbug
  /// remplace l'animation par ce bedbug, fixe. Un champ vide donne le bedbug par défaut.
  List<String> _avatarFrames() {
    final avatarText = _avatarTextControl.value?.trim() ?? '';
    if (avatarText.isEmpty) {
      return defaultSignatureAvatarFrames;
    }
    final catalogFrames = _catalogFramesControl.value;
    if (catalogFrames != null && catalogFrames.first == avatarText) {
      return catalogFrames;
    }
    return [avatarText];
  }

  /// Ouvre la page du catalogue des bedbugs et applique celui choisi.
  ///
  /// Le champ affiche la première frame du bedbug choisi, et ses frames sont retenues pour l'animer. Revenir sans
  /// choisir laisse le bedbug actuel en place.
  Future<void> _pickAvatarFromCatalog() async {
    final avatarFrames = await context.push<List<String>>(avatarPickerPath);
    if (avatarFrames == null) {
      return;
    }
    _catalogFramesControl.value = avatarFrames.length > 1 ? avatarFrames : null;
    _avatarTextControl.value = avatarFrames.first;
  }

  /// Valide le formulaire et déclenche l'enregistrement du profil.
  void _onSave() {
    if (!_form.valid) {
      _form.markAllAsTouched();
      return;
    }

    ref
        .read(appSignatureFormNotifierProvider.notifier)
        .save(
          pseudo: _pseudoControl.value!,
          avatarFrames: _avatarFrames(),
          colorArgb: (_colorControl.value ?? AppColors.primary).toARGB32(),
          ghostSpeed: _ghostSpeedControl.value ?? defaultGhostSpeed,
          avatarFrameSpeed: _avatarFrameSpeedControl.value ?? defaultAvatarFrameSpeed,
          socialLinks: _socialLinksControl.value ?? const {},
          bio: _bioControl.value,
          bioFont: _bioFontControl.value ?? TextFont.standard,
        );
  }
}
