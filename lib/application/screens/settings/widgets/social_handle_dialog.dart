import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/social_network_x.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/buttons/app_form_submit_button.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Popup de saisie de l'identifiant de l'utilisateur sur un réseau déjà choisi.
///
/// Seconde étape de l'ajout d'un lien : le réseau étant connu, l'URL se
/// construit sous les yeux de l'utilisateur pendant qu'il tape. Se ferme avec
/// l'identifiant normalisé, ou `null` s'il annule. À afficher via [show].
class SocialHandleDialog extends ConsumerStatefulWidget {
  /// Crée un [SocialHandleDialog].
  ///
  /// - [network] : réseau sur lequel saisir l'identifiant.
  const SocialHandleDialog({super.key, required this.network});

  /// Réseau sur lequel saisir l'identifiant.
  final SocialNetwork network;

  /// Affiche la popup et retourne l'identifiant normalisé, `null` si l'utilisateur annule.
  ///
  /// - [context] : contexte depuis lequel ouvrir la popup.
  /// - [network] : réseau sur lequel saisir l'identifiant.
  static Future<String?> show(BuildContext context, SocialNetwork network) {
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.barrier,
      builder: (dialogContext) => SocialHandleDialog(network: network),
    );
  }

  @override
  ConsumerState<SocialHandleDialog> createState() => _State();
}

class _State extends ConsumerState<SocialHandleDialog> {
  /// Contrôle du réseau, fixe : il sert à valider l'identifiant.
  late final _networkControl = FormControl<SocialNetwork>(value: widget.network);

  /// Contrôle de l'identifiant saisi.
  late final _handleControl = FormControl<String>(validators: [AppValidators.required]);

  /// Formulaire de la popup.
  ///
  /// La validité de l'identifiant dépend du réseau : elle est vérifiée au
  /// niveau du groupe par [AppValidators.socialHandle].
  late final FormGroup _form = FormGroup(
    {'network': _networkControl, 'handle': _handleControl},
    validators: [AppValidators.socialHandle('network', 'handle')],
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: Text(l10n.settingsSocialDialogTitle(widget.network.displayName)),
      // Une URL se lit toujours de gauche à droite, même dans une langue écrite
      // de droite à gauche : sans ça, l'identifiant saisi s'afficherait avant
      // le début de l'URL.
      content: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            AppFieldFocusPulse(
              child: ReactiveTextField<String>(
                formControl: _handleControl,
                autofocus: true,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSubmit(),
                decoration: InputDecoration(
                  hintText: l10n.settingsSocialHandleHint,
                  // `prefixIcon` plutôt que `prefixText` : le début de l'URL
                  // reste affiché même champ vide et non focus.
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 2),
                    child: Text(
                      widget.network.displayPrefix,
                      style: const TextStyle(fontSize: 15, color: AppColors.disabled),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => l10n.createRequiredFieldError,
                  'socialHandle': (_) => l10n.settingsSocialHandleError,
                },
              ),
            ),
            StreamBuilder<String?>(
              stream: _handleControl.valueChanges,
              initialData: _handleControl.value,
              builder: (context, _) {
                final handleInput = _handleControl.value?.trim() ?? '';
                if (handleInput.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildUrlPreview(handleInput);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        AppFormSubmitButton(form: _form, onTap: _onSubmit, child: Text(l10n.settingsSocialAdd)),
      ],
    );
  }

  /// Aperçu en direct de l'URL construite à partir de [handleInput].
  ///
  /// Une coche verte et l'URL complète si l'identifiant est valide, une croix
  /// rouge sinon : l'utilisateur voit l'URL se construire pendant qu'il tape.
  ///
  /// - [handleInput] : identifiant saisi, sans espaces de bordure.
  Widget _buildUrlPreview(String handleInput) {
    final handle = widget.network.normalizeHandle(handleInput);
    final isValid = handle != null;
    return Row(
      spacing: 6,
      children: [
        AppIcon(
          isValid ? AppIcons.checkCircle : AppIcons.cancel,
          size: 16,
          color: isValid ? AppColors.success : AppColors.failure,
        ),
        Expanded(
          child: Text(
            widget.network.profileUrl(handle ?? handleInput),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: isValid ? AppColors.onLight : AppColors.disabled),
          ),
        ),
      ],
    );
  }

  /// Valide la saisie et ferme la popup avec l'identifiant normalisé.
  void _onSubmit() {
    if (!_form.valid) {
      _form.markAllAsTouched();
      return;
    }
    Navigator.of(context).pop(widget.network.normalizeHandle(_handleControl.value!));
  }
}
