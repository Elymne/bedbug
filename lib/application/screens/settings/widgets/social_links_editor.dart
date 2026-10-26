import 'package:bedbug/application/screens/settings/linkedin_click_counter_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/clown_bedbug_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/linkedin_click_challenge_dialog.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/social_network_x.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Éditeur des liens vers les réseaux de l'utilisateur : liste des liens ajoutés et ligne d'ajout.
///
/// Les liens sont portés par [control], au plus un par réseau. La ligne
/// d'ajout ne propose que les réseaux pas encore renseignés. Ajouter un lien
/// LinkedIn demande une confirmation, parce que bon.
class SocialLinksEditor extends ConsumerStatefulWidget {
  /// Crée un [SocialLinksEditor].
  ///
  /// - [control] : contrôle portant l'identifiant de l'utilisateur par réseau.
  /// - [accentColor] : couleur des étiquettes de réseau, celle du profil.
  const SocialLinksEditor({super.key, required this.control, required this.accentColor});

  /// Contrôle portant l'identifiant de l'utilisateur par réseau.
  final FormControl<Map<SocialNetwork, String>> control;

  /// Couleur des étiquettes de réseau.
  final Color accentColor;

  @override
  ConsumerState<SocialLinksEditor> createState() => _State();
}

class _State extends ConsumerState<SocialLinksEditor> {
  /// Contrôle du réseau choisi dans la ligne d'ajout.
  late final _networkControl = FormControl<SocialNetwork>(validators: [AppValidators.required]);

  /// Contrôle de l'identifiant saisi dans la ligne d'ajout.
  late final _handleControl = FormControl<String>(validators: [AppValidators.required]);

  /// Formulaire de la ligne d'ajout.
  ///
  /// La validité de l'identifiant dépend du réseau choisi : elle est vérifiée
  /// au niveau du groupe par [AppValidators.socialHandle].
  late final FormGroup _addForm = FormGroup(
    {'network': _networkControl, 'handle': _handleControl},
    validators: [AppValidators.socialHandle('network', 'handle')],
  );

  @override
  void dispose() {
    _addForm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;

    return StreamBuilder<Map<SocialNetwork, String>?>(
      stream: widget.control.valueChanges,
      initialData: widget.control.value,
      builder: (context, _) {
        final links = widget.control.value ?? const {};
        final availableNetworks = SocialNetwork.values.where((network) => !links.containsKey(network)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final entry in links.entries)
              Row(
                spacing: 8,
                children: [
                  AppTag(label: entry.key.displayName, color: widget.accentColor),
                  Expanded(
                    child: Text(
                      entry.key.profileUrl(entry.value).replaceFirst(RegExp(r'^https://(www\.)?'), ''),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: AppColors.onLight),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _remove(entry.key),
                    tooltip: l10n.settingsSocialRemove,
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.disabled),
                  ),
                ],
              ),
            if (availableNetworks.isNotEmpty) ...[
              ReactiveDropdownField<SocialNetwork>(
                formControl: _networkControl,
                isExpanded: true,
                hint: Text(l10n.settingsSocialNetworkHint),
                validationMessages: {ValidationMessage.required: (_) => l10n.createRequiredFieldError},
                items: [
                  for (final network in availableNetworks)
                    DropdownMenuItem(value: network, child: Text(network.displayName)),
                ],
              ),
              StreamBuilder<Map<String, Object?>?>(
                stream: _addForm.valueChanges,
                initialData: _addForm.value,
                builder: (context, _) {
                  final network = _networkControl.value;
                  final handleInput = _handleControl.value?.trim() ?? '';
                  Widget? urlPrefix;
                  if (network != null) {
                    urlPrefix = Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text(
                        network.displayPrefix,
                        style: const TextStyle(fontSize: 15, color: AppColors.disabled),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      ReactiveTextField<String>(
                        formControl: _handleControl,
                        decoration: InputDecoration(
                          hintText: l10n.settingsSocialHandleHint,
                          // `prefixIcon` plutôt que `prefixText` : le début
                          // de l'URL reste affiché même champ vide et non focus.
                          prefixIcon: urlPrefix,
                          prefixIconConstraints: const BoxConstraints(),
                          suffixIcon: IconButton(
                            onPressed: _add,
                            tooltip: l10n.settingsSocialAdd,
                            icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          ),
                        ),
                        validationMessages: {
                          ValidationMessage.required: (_) => l10n.createRequiredFieldError,
                          'socialHandle': (_) => l10n.settingsSocialHandleError,
                        },
                      ),
                      if (network != null && handleInput.isNotEmpty) _buildUrlPreview(network, handleInput),
                    ],
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  /// Ajoute le lien saisi dans la ligne d'ajout à [SocialLinksEditor.control].
  ///
  /// LinkedIn n'est jamais ajouté : il déclenche à la place le parcours de moquerie.
  Future<void> _add() async {
    if (!_addForm.valid) {
      _addForm.markAllAsTouched();
      return;
    }

    final network = _networkControl.value!;
    // LinkedIn n'est jamais ajouté : l'utilisateur a droit au parcours de
    // moquerie, puis repart les mains vides.
    if (network == SocialNetwork.linkedin) {
      await _mockLinkedin();
      _addForm.reset();
      return;
    }

    final handle = network.normalizeHandle(_handleControl.value!)!;
    widget.control.value = {...?widget.control.value, network: handle};
    _addForm.reset();
  }

  /// Aperçu en direct de l'URL construite à partir de [handleInput] sur [network].
  ///
  /// Une coche verte et l'URL complète si l'identifiant est valide, une croix
  /// rouge sinon : l'utilisateur voit l'URL se construire pendant qu'il tape.
  Widget _buildUrlPreview(SocialNetwork network, String handleInput) {
    final handle = network.normalizeHandle(handleInput);
    final isValid = handle != null;
    return Row(
      spacing: 6,
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: isValid ? AppColors.success : AppColors.failure,
        ),
        Expanded(
          child: Text(
            network.profileUrl(handle ?? handleInput),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: isValid ? AppColors.onLight : AppColors.disabled),
          ),
        ),
      ],
    );
  }

  /// Retire le lien du réseau [network].
  void _remove(SocialNetwork network) {
    widget.control.value = {...?widget.control.value}..remove(network);
  }

  /// Fait passer l'utilisateur par le parcours de moquerie LinkedIn, qui n'ajoute jamais rien.
  ///
  /// Trois étapes : une popup de moquerie, puis [linkedinRequiredClicks]
  /// clics à faire, puis le bedbug clown qui le traite de bouffon, après quoi
  /// l'app se ferme. Qu'il abandonne en route ou aille au bout, le lien n'est
  /// pas créé : c'est toute la blague.
  Future<void> _mockLinkedin() async {
    final l10n = context.loc;
    final isConfirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrier,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          title: Text(l10n.settingsLinkedinDialogTitle),
          content: Text(l10n.settingsLinkedinDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.settingsLinkedinDialogCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.settingsLinkedinDialogConfirm),
            ),
          ],
        );
      },
    );
    if (isConfirmed != true || !mounted) {
      return;
    }

    final hasClickedEnough = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrier,
      // Fermer en tapant à côté serait trop facile.
      barrierDismissible: false,
      builder: (dialogContext) => const LinkedinClickChallengeDialog(),
    );
    if (hasClickedEnough != true || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: AppColors.barrier,
      builder: (dialogContext) => const ClownBedbugDialog(),
    );

    // Coup de grâce : le bouffon est mis à la porte. Ferme l'app proprement
    // sur Android (comme un retour depuis l'écran d'accueil) ; ignoré sur iOS,
    // où Apple interdit aux apps de se fermer d'elles-mêmes. Les modifications
    // du profil non enregistrées sont perdues, ça fait partie de la blague.
    await SystemNavigator.pop();
  }
}
