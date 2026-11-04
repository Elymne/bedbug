import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.failure.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.params.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [AppSignatureFormNotifier].
final appSignatureFormNotifierProvider = AsyncNotifierProvider<AppSignatureFormNotifier, AppSignatureFormState>(
  AppSignatureFormNotifier.new,
);

/// Notifier gérant l'enregistrement du profil de l'utilisateur du téléphone.
class AppSignatureFormNotifier extends AsyncNotifier<AppSignatureFormState> {
  /// Cas d'usage d'enregistrement du profil local.
  late final _saveLocalSignatureUsecase = ref.read(saveLocalSignatureUsecaseProvider);

  @override
  Future<AppSignatureFormState> build() async {
    return AppSignatureFormState();
  }

  /// Enregistre le profil saisi.
  ///
  /// - [pseudo] : pseudo saisi.
  /// - [avatarFrames] : frames du bedbug choisi.
  /// - [colorArgb] : couleur de l'effet ghost de l'icône en ARGB 32 bits.
  /// - [ghostSpeed] : vitesse de l'effet ghost.
  /// - [avatarFrameSpeed] : vitesse de l'animation du bedbug.
  /// - [socialLinks] : identifiants saisis par réseau.
  /// - [bio] : description saisie, `null` ou vide pour ne pas en avoir.
  /// - [bioFont] : police choisie pour la description.
  Future<void> save({
    required String pseudo,
    required List<String> avatarFrames,
    required int colorArgb,
    required double ghostSpeed,
    required double avatarFrameSpeed,
    required Map<SocialNetwork, String> socialLinks,
    required TextFont bioFont,
    String? bio,
  }) async {
    state = const AsyncLoading();

    final result = await _saveLocalSignatureUsecase(
      SaveLocalSignatureParams(
        pseudo: pseudo,
        avatarFrames: avatarFrames,
        colorArgb: colorArgb,
        ghostSpeed: ghostSpeed,
        avatarFrameSpeed: avatarFrameSpeed,
        socialLinks: socialLinks,
        bio: bio,
        bioFont: bioFont,
      ),
    );
    result.fold(
      onFailure: (SaveLocalSignatureFailure failure) {
        final message = switch (failure) {
          SaveLocalSignatureFailure.invalidProfile => ref.l10n.settingsProfileInvalid,
          SaveLocalSignatureFailure.storageError => ref.l10n.homeGetContentsStorageError,
          SaveLocalSignatureFailure.unknown => ref.l10n.settingsProfileSaveError,
        };
        state = AsyncData(AppSignatureFormState(failureMessage: message));
      },
      onSuccess: (Signature signature) {
        state = AsyncData(AppSignatureFormState(savedSignature: signature));
      },
    );
  }
}

/// État de l'enregistrement du profil.
class AppSignatureFormState extends NotifierState {
  /// Crée un [AppSignatureFormState].
  ///
  /// - [savedSignature] : profil tout juste enregistré, `null` tant qu'aucun enregistrement n'a réussi.
  /// - [failureMessage] : message d'erreur après un échec d'enregistrement.
  AppSignatureFormState({this.savedSignature, super.failureMessage});

  /// Profil tout juste enregistré.
  final Signature? savedSignature;
}
