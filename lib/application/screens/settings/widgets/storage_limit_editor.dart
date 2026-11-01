import 'package:bedbug/application/screens/settings/storage_limit_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Choix de la limite de stockage : une ligne par limite proposée, une option « personnalisée » et son champ.
///
/// Une limite proposée s'applique dès le tap, comme la langue. L'option
/// personnalisée active le champ, qui attend ensuite une validation : appliquer
/// chaque frappe supprimerait des contenus en passant par des valeurs que
/// l'utilisateur n'a pas choisies.
class StorageLimitEditor extends ConsumerStatefulWidget {
  /// Crée un [StorageLimitEditor].
  ///
  /// - [limitInBytes] : limite actuelle, en octets.
  const StorageLimitEditor({super.key, required this.limitInBytes});

  /// Limite actuelle, en octets.
  final int limitInBytes;

  @override
  ConsumerState<StorageLimitEditor> createState() => _State();
}

class _State extends ConsumerState<StorageLimitEditor> {
  /// Contrôle de la limite personnalisée, en mégaoctets.
  ///
  /// Prérempli si la limite actuelle n'est pas une limite proposée. Son état
  /// porte aussi le choix de l'option : activé, c'est l'option personnalisée
  /// qui est sélectionnée.
  late final _customLimitControl = FormControl<String>(
    value: _isCustomLimit ? '${widget.limitInBytes ~/ bytesPerMegabyte}' : null,
    validators: [AppValidators.required, AppValidators.storageLimit],
    disabled: !_isCustomLimit,
  );

  /// `true` si la limite actuelle a été définie par l'utilisateur.
  bool get _isCustomLimit {
    return !storageLimitPresetsInBytes.contains(widget.limitInBytes);
  }

  /// Message affiché quand la limite saisie sort des bornes autorisées.
  String get _invalidMessage {
    return context.loc.settingsStorageCustomInvalid(minStorageLimitInMegabytes, maxStorageLimitInMegabytes);
  }

  @override
  void dispose() {
    _customLimitControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    const optionStyle = TextStyle(fontSize: 15, color: AppColors.onLight);
    const selectedIcon = Icon(Icons.check, color: AppColors.primary);

    return StreamBuilder<ControlStatus>(
      stream: _customLimitControl.statusChanged,
      initialData: _customLimitControl.status,
      builder: (context, _) {
        final isCustomSelected = _customLimitControl.enabled;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(l10n.settingsStorageDescription, style: const TextStyle(fontSize: 13, color: AppColors.disabled)),
            for (final preset in storageLimitPresetsInBytes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsStorageMegabytes(preset ~/ bytesPerMegabyte), style: optionStyle),
                trailing: !isCustomSelected && preset == widget.limitInBytes ? selectedIcon : null,
                onTap: () => _onPresetSelected(preset),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsStorageCustomOption, style: optionStyle),
              trailing: isCustomSelected ? selectedIcon : null,
              onTap: _onCustomSelected,
            ),
            AppFieldFocusPulse(
              child: ReactiveTextField<String>(
                formControl: _customLimitControl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _applyCustomLimit(),
                decoration: InputDecoration(
                  labelText: l10n.settingsStorageCustomLabel,
                  hintText: l10n.settingsStorageCustomHint,
                  suffixIcon: IconButton(
                    onPressed: isCustomSelected ? _applyCustomLimit : null,
                    tooltip: l10n.settingsStorageCustomApply,
                    icon: const Icon(Icons.check),
                    color: AppColors.primary,
                    disabledColor: AppColors.disabled,
                  ),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => _invalidMessage,
                  'storageLimit': (_) => _invalidMessage,
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Applique la limite proposée [preset] et désactive le champ personnalisé.
  ///
  /// - [preset] : limite choisie, en octets.
  void _onPresetSelected(int preset) {
    FocusScope.of(context).unfocus();
    _customLimitControl.markAsDisabled();
    ref.read(storageLimitNotifierProvider.notifier).setLimit(preset);
  }

  /// Active le champ personnalisé et y place le curseur, sans rien appliquer.
  void _onCustomSelected() {
    _customLimitControl.markAsEnabled();
    // Un champ désactivé refuse le focus : il faut attendre qu'il soit reconstruit activé.
    WidgetsBinding.instance.addPostFrameCallback((_) => _customLimitControl.focus());
  }

  /// Applique la limite saisie si elle est valide.
  void _applyCustomLimit() {
    if (!_customLimitControl.valid) {
      _customLimitControl.markAsTouched();
      return;
    }
    final megabytes = int.parse(_customLimitControl.value!.trim());
    FocusScope.of(context).unfocus();
    ref.read(storageLimitNotifierProvider.notifier).setLimit(megabytes * bytesPerMegabyte);
  }
}
