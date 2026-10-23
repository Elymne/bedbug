import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [UserSettingsNotifier].
final userSettingsNotifierProvider = AsyncNotifierProvider<UserSettingsNotifier, UserSettingsState>(
  UserSettingsNotifier.new,
);

/// Notifier des réglages de l'appareil (publication anonyme par défaut, etc.).
///
/// Chaque réglage est enregistré dès qu'il change, sans bouton de validation.
class UserSettingsNotifier extends AsyncNotifier<UserSettingsState> {
  /// Cas d'usage de lecture des réglages.
  late final _getSettingsUsecase = ref.read(getSettingsUsecaseProvider);

  /// Cas d'usage d'enregistrement des réglages.
  late final _saveSettingsUsecase = ref.read(saveSettingsUsecaseProvider);

  @override
  Future<UserSettingsState> build() async {
    final result = await _getSettingsUsecase(const NoParams());
    return result.fold(
      onFailure: (GetSettingsFailure failure) {
        final message = switch (failure) {
          GetSettingsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetSettingsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetSettingsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return UserSettingsState(settings: const UserSettings.empty(), failureMessage: message);
      },
      onSuccess: (UserSettings settings) => UserSettingsState(settings: settings),
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
    state = AsyncData(UserSettingsState(settings: updated));

    final result = await _saveSettingsUsecase(SaveSettingsParams(settings: updated));
    result.fold(
      onFailure: (SaveSettingsFailure failure) {
        state = AsyncData(UserSettingsState(settings: previous, failureMessage: ref.l10n.settingsSaveError));
      },
      onSuccess: (_) {},
    );
  }
}

/// État des réglages de l'appareil.
class UserSettingsState extends NotifierState {
  /// Crée un [UserSettingsState].
  ///
  /// - [settings] : réglages actuels.
  /// - [failureMessage] : message d'erreur éventuel (lecture ou enregistrement).
  UserSettingsState({required this.settings, super.failureMessage});

  /// Réglages actuels.
  final UserSettings settings;
}
