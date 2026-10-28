import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:bedbug/features/signature/domain/usecases/save_local_signature_usecase.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveSignatureNotifier].
final saveSignatureNotifierProvider = AsyncNotifierProvider<SaveSignatureNotifier, SaveSignatureState>(
  SaveSignatureNotifier.new,
);

/// Notifier gérant l'enregistrement du profil de l'utilisateur du téléphone.
class SaveSignatureNotifier extends AsyncNotifier<SaveSignatureState> {
  /// Cas d'usage d'enregistrement du profil local.
  late final _saveLocalSignatureUsecase = ref.read(saveLocalSignatureUsecaseProvider);

  @override
  Future<SaveSignatureState> build() async {
    return SaveSignatureState();
  }

  /// Enregistre le profil saisi.
  ///
  /// - [pseudo] : pseudo saisi.
  /// - [avatarText] : icône texte saisie.
  /// - [colorArgb] : couleur de l'effet ghost de l'icône en ARGB 32 bits.
  /// - [ghostSpeed] : vitesse de l'effet ghost.
  /// - [socialLinks] : identifiants saisis par réseau.
  /// - [bio] : description saisie, `null` ou vide pour ne pas en avoir.
  /// - [bioFont] : police choisie pour la description.
  Future<void> save({
    required String pseudo,
    required String avatarText,
    required int colorArgb,
    required double ghostSpeed,
    required Map<SocialNetwork, String> socialLinks,
    required TextFont bioFont,
    String? bio,
  }) async {
    state = const AsyncLoading();

    final result = await _saveLocalSignatureUsecase(
      SaveLocalSignatureParams(
        pseudo: pseudo,
        avatarText: avatarText,
        colorArgb: colorArgb,
        ghostSpeed: ghostSpeed,
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
        state = AsyncData(SaveSignatureState(failureMessage: message));
      },
      onSuccess: (Signature signature) {
        state = AsyncData(SaveSignatureState(savedSignature: signature));
      },
    );
  }
}

/// État de l'enregistrement du profil.
class SaveSignatureState extends NotifierState {
  /// Crée un [SaveSignatureState].
  ///
  /// - [savedSignature] : profil tout juste enregistré, `null` tant qu'aucun enregistrement n'a réussi.
  /// - [failureMessage] : message d'erreur après un échec d'enregistrement.
  SaveSignatureState({this.savedSignature, super.failureMessage});

  /// Profil tout juste enregistré.
  final Signature? savedSignature;
}
