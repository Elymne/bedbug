import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/enums/social_network.dart';
import 'package:bedbug/features/user/domain/usecases/save_local_user_usecase.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveProfileNotifier].
final saveProfileNotifierProvider = AsyncNotifierProvider<SaveProfileNotifier, SaveProfileState>(
  SaveProfileNotifier.new,
);

/// Notifier gérant l'enregistrement du profil de l'utilisateur du téléphone.
class SaveProfileNotifier extends AsyncNotifier<SaveProfileState> {
  /// Cas d'usage d'enregistrement du profil local.
  late final _saveLocalUserUsecase = ref.read(saveLocalUserUsecaseProvider);

  @override
  Future<SaveProfileState> build() async {
    return SaveProfileState();
  }

  /// Enregistre le profil saisi.
  ///
  /// - [pseudo] : pseudo saisi.
  /// - [avatarText] : icône texte saisie.
  /// - [colorArgb] : couleur de l'effet ghost de l'icône en ARGB 32 bits.
  /// - [ghostSpeed] : vitesse de l'effet ghost.
  /// - [socialLinks] : identifiants saisis par réseau.
  Future<void> save({
    required String pseudo,
    required String avatarText,
    required int colorArgb,
    required double ghostSpeed,
    required Map<SocialNetwork, String> socialLinks,
  }) async {
    state = const AsyncLoading();

    final result = await _saveLocalUserUsecase(
      SaveLocalUserParams(
        pseudo: pseudo,
        avatarText: avatarText,
        colorArgb: colorArgb,
        ghostSpeed: ghostSpeed,
        socialLinks: socialLinks,
      ),
    );
    result.fold(
      onFailure: (SaveLocalUserFailure failure) {
        final message = switch (failure) {
          SaveLocalUserFailure.invalidProfile => ref.l10n.settingsProfileInvalid,
          SaveLocalUserFailure.storageError => ref.l10n.homeGetContentsStorageError,
          SaveLocalUserFailure.unknown => ref.l10n.settingsProfileSaveError,
        };
        state = AsyncData(SaveProfileState(failureMessage: message));
      },
      onSuccess: (User user) {
        state = AsyncData(SaveProfileState(savedUser: user));
      },
    );
  }
}

/// État de l'enregistrement du profil.
class SaveProfileState extends NotifierState {
  /// Crée un [SaveProfileState].
  ///
  /// - [savedUser] : profil tout juste enregistré, `null` tant qu'aucun enregistrement n'a réussi.
  /// - [failureMessage] : message d'erreur après un échec d'enregistrement.
  SaveProfileState({this.savedUser, super.failureMessage});

  /// Profil tout juste enregistré.
  final User? savedUser;
}
