import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.failure.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.usecase.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.failure.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.params.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [PublishingSectionNotifier].
final publishingSectionNotifierProvider = AsyncNotifierProvider<PublishingSectionNotifier, PublishingSectionState>(
  PublishingSectionNotifier.new,
);

/// Notifier des réglages de l'appareil (publication anonyme par défaut, etc.).
///
/// Chaque réglage est enregistré dès qu'il change, sans bouton de validation.
class PublishingSectionNotifier extends AsyncNotifier<PublishingSectionState> {
  /// Cas d'usage de lecture des réglages.
  late final _getSettingsUsecase = ref.read(getSettingsUsecaseProvider);

  /// Cas d'usage d'enregistrement des réglages.
  late final _saveSettingsUsecase = ref.read(saveSettingsUsecaseProvider);

  @override
  Future<PublishingSectionState> build() async {
    final result = await _getSettingsUsecase(const NoParams());
    return result.fold(
      onFailure: (GetSettingsFailure failure) {
        final message = switch (failure) {
          GetSettingsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetSettingsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetSettingsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return PublishingSectionState(settings: defaultUserSettings, failureMessage: message);
      },
      onSuccess: (UserSettings settings) => PublishingSectionState(settings: settings),
    );
  }

  /// Active ou désactive la publication anonyme par défaut des nouveaux contenus.
  ///
  /// La case est cochée immédiatement à l'écran, puis enregistrée. En cas
  /// d'échec, elle revient à sa valeur précédente avec un message d'erreur.
  ///
  /// - [isEnabled] : `true` pour publier anonymement par défaut.
  Future<void> setAnonymousByDefault(bool isEnabled) async {
    final previous = state.requireValue.settings;
    final updated = previous.copyWith(isAnonymousByDefault: isEnabled);
    state = AsyncData(PublishingSectionState(settings: updated));

    final result = await _saveSettingsUsecase(SaveSettingsParams(settings: updated));
    result.fold(
      onFailure: (SaveSettingsFailure failure) {
        state = AsyncData(PublishingSectionState(settings: previous, failureMessage: ref.l10n.settingsSaveError));
      },
      onSuccess: (_) {},
    );
  }
}

/// État des réglages de l'appareil.
class PublishingSectionState extends NotifierState {
  /// Crée un [PublishingSectionState].
  ///
  /// - [settings] : réglages actuels.
  /// - [failureMessage] : message d'erreur éventuel (lecture ou enregistrement).
  PublishingSectionState({required this.settings, super.failureMessage});

  /// Réglages actuels.
  final UserSettings settings;
}
