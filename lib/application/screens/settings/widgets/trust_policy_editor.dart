import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/content/domain/services/domain_rule_service.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Éditeur des deux listes (whitelist et greylist) d'une famille d'URLs : ajout et retrait.
///
/// Les règles saisies passent par les vérifications du domaine (domaine
/// mal formé ou piégé, suffixe public trop large) : un refus est expliqué
/// par une snackbar, et la saisie reste dans le champ pour être corrigée.
class TrustPolicyEditor extends ConsumerStatefulWidget {
  /// Crée un [TrustPolicyEditor].
  ///
  /// - [family] : famille d'URLs dont les listes sont éditées.
  /// - [policy] : listes actuelles de cette famille.
  const TrustPolicyEditor({super.key, required this.family, required this.policy});

  /// Famille d'URLs dont les listes sont éditées.
  final UrlFamily family;

  /// Listes actuelles de cette famille.
  final UrlTrustPolicy policy;

  @override
  ConsumerState<TrustPolicyEditor> createState() => _State();
}

class _State extends ConsumerState<TrustPolicyEditor> {
  /// Contrôle de la règle en cours de saisie.
  late final _ruleInputControl = FormControl<String>();

  @override
  void dispose() {
    _ruleInputControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          l10n.trustTrustedLabel,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onLight),
        ),
        _buildRules(widget.policy.trustedRules),
        const SizedBox(height: 4),
        Text(
          l10n.trustGreyLabel,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onLight),
        ),
        _buildRules(widget.policy.greyRules),
        AppFieldFocusPulse(
          child: ReactiveTextField<String>(
            formControl: _ruleInputControl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: l10n.trustAddRuleHint,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addRule(TrustLevel.trusted),
                    tooltip: l10n.trustAddToTrusted,
                    icon: const AppIcon(AppIcons.verified, color: AppColors.success),
                  ),
                  IconButton(
                    onPressed: () => _addRule(TrustLevel.grey),
                    tooltip: l10n.trustAddToGrey,
                    icon: const AppIcon(AppIcons.blur, color: AppColors.disabled),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Lignes des règles [rules] séparées par un trait, ou un texte indiquant que la liste est vide.
  ///
  /// - [rules] : règles de la liste affichée.
  Widget _buildRules(List<DomainRule> rules) {
    final l10n = context.loc;
    if (rules.isEmpty) {
      return Text(l10n.trustEmptyList, style: const TextStyle(color: AppColors.disabled));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final rule in rules) ...[
          // Même retrait que le séparateur, pour que le texte et le trait partent du même bord.
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 4, top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  // Un domaine se lit toujours de gauche à droite, même en arabe.
                  child: Text(
                    ref.read(domainRuleServiceProvider).patternOf(rule),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 15, color: AppColors.onLight),
                  ),
                ),
                IconButton(
                  onPressed: () => _run(
                    ref.read(trustSettingsNotifierProvider.notifier).removeRule(family: widget.family, rule: rule),
                  ),
                  tooltip: l10n.settingsSocialRemove,
                  icon: const AppIcon(AppIcons.close, color: AppColors.onLight),
                ),
              ],
            ),
          ),
          if (rule != rules.last) const AppListSeparator(),
        ],
      ],
    );
  }

  /// Ajoute la règle saisie à la liste [level], et vide le champ en cas de succès.
  Future<void> _addRule(TrustLevel level) async {
    final input = _ruleInputControl.value?.trim() ?? '';
    if (input.isEmpty) {
      return;
    }
    final failureMessage = await ref
        .read(trustSettingsNotifierProvider.notifier)
        .addRule(family: widget.family, level: level, input: input);
    if (!mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      return;
    }
    _ruleInputControl.reset();
  }

  /// Attend la modification [action] et affiche son éventuel message d'erreur.
  Future<void> _run(Future<String?> action) async {
    final failureMessage = await action;
    if (failureMessage != null && mounted) {
      AppSnackbar.showError(context, failureMessage);
    }
  }
}
