import 'package:bedbug/application/formatters/avatar_text_input_formatter.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/settings/local_signature_notifier.dart';
import 'package:bedbug/application/screens/settings/save_signature_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/signature_color_selector.dart';
import 'package:bedbug/application/screens/settings/widgets/social_links_editor.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/features/signature/domain/extensions/signature_text_extension.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
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
/// couleur choisie) et du pseudo, puis les champs : pseudo, icône texte
/// (écrite à la main ou choisie dans le catalogue), couleur et liens vers les
/// réseaux.
class SignatureSection extends ConsumerStatefulWidget {
  /// Crée un [SignatureSection].
  ///
  /// - [signature] : profil enregistré servant de valeurs initiales, `null` s'il n'a jamais été configuré.
  const SignatureSection({super.key, required this.signature});

  /// Profil enregistré servant de valeurs initiales.
  final Signature? signature;

  @override
  ConsumerState<SignatureSection> createState() => _State();
}

class _State extends ConsumerState<SignatureSection> {
  /// Contrôle du pseudo.
  late final _pseudoControl = FormControl<String>(
    value: widget.signature?.pseudo,
    validators: [AppValidators.required, AppValidators.pseudo],
  );

  /// Contrôle de l'icône texte.
  late final _avatarTextControl = FormControl<String>(
    value: widget.signature?.avatarText ?? defaultSignatureAvatarText,
    validators: [AppValidators.required, AppValidators.avatarText],
  );

  /// Contrôle de la couleur de l'effet ghost.
  late final _colorControl = FormControl<Color>(value: _initialColor());

  /// Contrôle de la vitesse de l'effet ghost.
  late final _ghostSpeedControl = FormControl<double>(value: widget.signature?.ghostSpeed ?? defaultGhostSpeed);

  /// Contrôle des identifiants par réseau.
  late final _socialLinksControl = FormControl<Map<SocialNetwork, String>>(
    value: widget.signature?.socialLinks ?? const {},
  );

  /// Formulaire du profil.
  late final FormGroup _form = FormGroup({
    'pseudo': _pseudoControl,
    'avatarText': _avatarTextControl,
    'color': _colorControl,
    'ghostSpeed': _ghostSpeedControl,
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
    final saveProfileNotifierWatcher = ref.watch(saveSignatureNotifierProvider);

    ref.listen(saveSignatureNotifierProvider, (previous, next) {
      if (next.isLoading) return;
      final saveState = next.value;
      if (saveState == null) return;
      final savedSignature = saveState.savedSignature;
      if (savedSignature != null) {
        ref.read(localSignatureNotifierProvider.notifier).setSignature(savedSignature);
        AppSnackbar.showSuccess(context, l10n.settingsProfileSaved);
        return;
      }
      if (saveState.failureMessage != null) {
        AppSnackbar.showError(context, saveState.failureMessage!);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        StreamBuilder<Map<String, Object?>?>(
          stream: _form.valueChanges,
          initialData: _form.value,
          builder: (context, _) {
            final avatarText = _avatarTextControl.value?.trim() ?? '';
            final pseudo = _pseudoControl.value?.trim() ?? '';
            return Column(
              spacing: 8,
              children: [
                const SizedBox(height: 8),
                AppSignatureAvatar(
                  avatarText: avatarText.isEmpty ? defaultSignatureAvatarText : avatarText,
                  ghostColor: _colorControl.value ?? AppColors.primary,
                  ghostSpeed: _ghostSpeedControl.value ?? defaultGhostSpeed,
                ),
                AppPrefixedText(
                  prefix: AppPrefixes.signature,
                  text: pseudo.isEmpty ? anonymousSignature.pseudo : pseudo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onLight),
                ),
              ],
            );
          },
        ),
        ReactiveTextField<String>(
          formControl: _pseudoControl,
          maxLength: maxPseudoLength,
          inputFormatters: [FilteringTextInputFormatter.allow(pseudoAllowedCharacter)],
          decoration: InputDecoration(
            labelText: l10n.settingsPseudoLabel,
            prefixText: AppPrefixes.signature,
            prefixStyle: const TextStyle(color: AppColors.primary),
          ),
          validationMessages: {
            ValidationMessage.required: (_) => l10n.createRequiredFieldError,
            'pseudo': (_) => l10n.settingsPseudoError,
          },
        ),
        ReactiveTextField<String>(
          formControl: _avatarTextControl,
          maxLength: _kAvatarMaxLength,
          inputFormatters: const [AvatarTextInputFormatter()],
          decoration: InputDecoration(
            labelText: l10n.settingsAvatarLabel,
            suffixIcon: IconButton(
              onPressed: _pickAvatarFromCatalog,
              tooltip: l10n.settingsAvatarBrowse,
              icon: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
            ),
          ),
          validationMessages: {
            ValidationMessage.required: (_) => l10n.createRequiredFieldError,
            'avatarText': (_) => l10n.settingsAvatarError,
          },
        ),
        Text(l10n.settingsColorLabel),
        SignatureColorSelector(control: _colorControl),
        Text(l10n.settingsGhostSpeedLabel),
        ReactiveSlider(
          formControl: _ghostSpeedControl,
          min: minGhostSpeed,
          max: maxGhostSpeed,
          // Pas de 0,25 entre les bornes.
          divisions: ((maxGhostSpeed - minGhostSpeed) / 0.25).round(),
          labelBuilder: (value) => '×${value.toStringAsFixed(2)}',
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
          alignment: Alignment.centerRight,
          child: AppGradientButton(
            isLoading: saveProfileNotifierWatcher.isLoading,
            onTap: _onSave,
            child: Text(l10n.settingsProfileSaveButton),
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

  /// Ouvre la page du catalogue d'icônes et applique le kaomoji choisi.
  ///
  /// Revenir sans choisir laisse l'icône actuelle en place.
  Future<void> _pickAvatarFromCatalog() async {
    final kaomoji = await context.push<String>(avatarPickerPath);
    if (kaomoji == null) {
      return;
    }
    _avatarTextControl.value = kaomoji;
  }

  /// Valide le formulaire et déclenche l'enregistrement du profil.
  void _onSave() {
    if (!_form.valid) {
      _form.markAllAsTouched();
      return;
    }

    ref
        .read(saveSignatureNotifierProvider.notifier)
        .save(
          pseudo: _pseudoControl.value!,
          avatarText: _avatarTextControl.value!,
          colorArgb: (_colorControl.value ?? AppColors.primary).toARGB32(),
          ghostSpeed: _ghostSpeedControl.value ?? defaultGhostSpeed,
          socialLinks: _socialLinksControl.value ?? const {},
        );
  }
}
