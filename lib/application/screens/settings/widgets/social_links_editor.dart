import 'package:bedbug/application/screens/settings/linkedin_click_counter_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/clown_bedbug_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/linkedin_click_challenge_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/social_handle_dialog.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/social_network_x.dart';
import 'package:bedbug/application/widgets/fields/app_select_box.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Éditeur des liens vers les réseaux de l'utilisateur : liste des liens ajoutés et ajout en deux étapes.
///
/// Les liens sont portés par [control], au plus un par réseau. L'ajout commence
/// par le choix d'un réseau, parmi ceux pas encore renseignés, puis se termine
/// dans une popup de saisie de l'identifiant. Ajouter un lien LinkedIn demande
/// une confirmation, parce que bon.
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
  /// Contrôle du réseau en cours d'ajout, vidé dès la fin de l'ajout.
  late final _networkControl = FormControl<SocialNetwork>();

  /// Formulaire du choix du réseau.
  late final FormGroup _addForm = FormGroup({'network': _networkControl});

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
        final availableNetworks = SocialNetwork.values.where((network) => !links.containsKey(network));

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
                    icon: const AppIcon(AppIcons.close, size: 18, color: AppColors.disabled),
                  ),
                ],
              ),
            if (availableNetworks.isNotEmpty)
              AppSelectBox<SocialNetwork>(
                control: _networkControl,
                label: l10n.settingsSocialAddLabel,
                hintText: l10n.settingsSocialNetworkHint,
                options: [
                  for (final network in availableNetworks) AppSelectOption(value: network, label: network.displayName),
                ],
                onSelected: _onNetworkSelected,
              ),
          ],
        );
      },
    );
  }

  /// Demande l'identifiant sur [network] et ajoute le lien à [SocialLinksEditor.control].
  ///
  /// LinkedIn n'est jamais ajouté : il déclenche à la place le parcours de moquerie.
  ///
  /// - [network] : réseau tout juste choisi.
  Future<void> _onNetworkSelected(SocialNetwork network) async {
    final handle = await SocialHandleDialog.show(context, network);
    if (!mounted) {
      return;
    }
    _networkControl.reset();
    if (handle == null) {
      return;
    }

    // LinkedIn n'est jamais ajouté : l'utilisateur a droit au parcours de
    // moquerie, puis repart les mains vides.
    if (network == SocialNetwork.linkedin) {
      await _mockLinkedin();
      return;
    }

    widget.control.value = {...?widget.control.value, network: handle};
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
