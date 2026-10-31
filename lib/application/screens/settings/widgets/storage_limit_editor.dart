import 'package:bedbug/application/screens/settings/storage_limit_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Choix de la limite de stockage : une ligne par limite proposée, et un champ pour une valeur personnalisée.
///
/// Une limite proposée s'applique dès le tap, comme la langue. Le champ, lui, attend une validation : appliquer chaque
/// frappe supprimerait des contenus en passant par des valeurs que l'utilisateur n'a pas choisies.
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
  /// Contrôle de la limite personnalisée, en mégaoctets, prérempli si la limite actuelle n'est pas une limite proposée.
  late final _customLimitControl = FormControl<String>(
    value: _isCustomLimit ? '${widget.limitInBytes ~/ bytesPerMegabyte}' : null,
    validators: [AppValidators.required, AppValidators.storageLimit],
  );

  /// `true` si la limite actuelle a été définie par l'utilisateur.
  bool get _isCustomLimit {
    return !storageLimitPresetsInBytes.contains(widget.limitInBytes);
  }

  @override
  void dispose() {
    _customLimitControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(l10n.settingsStorageDescription, style: const TextStyle(fontSize: 13, color: AppColors.disabled)),
        for (final preset in storageLimitPresetsInBytes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.settingsStorageMegabytes(preset ~/ bytesPerMegabyte),
              style: const TextStyle(fontSize: 15, color: AppColors.onLight),
            ),
            trailing: preset == widget.limitInBytes ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () => ref.read(storageLimitNotifierProvider.notifier).setLimit(preset),
          ),
        ReactiveTextField<String>(
          formControl: _customLimitControl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.settingsStorageCustomLabel,
            suffixIcon: IconButton(
              onPressed: _applyCustomLimit,
              tooltip: l10n.settingsStorageCustomApply,
              icon: Icon(Icons.check, color: _isCustomLimit ? AppColors.primary : AppColors.onLight),
            ),
          ),
          validationMessages: {
            ValidationMessage.required: (_) => _invalidMessage,
            'storageLimit': (_) => _invalidMessage,
          },
        ),
      ],
    );
  }

  /// Message affiché quand la limite saisie sort des bornes autorisées.
  String get _invalidMessage {
    return context.loc.settingsStorageCustomInvalid(minStorageLimitInMegabytes, maxStorageLimitInMegabytes);
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
