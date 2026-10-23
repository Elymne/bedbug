import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/usecases/get_local_signature_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [LocalSignatureNotifier].
final localSignatureNotifierProvider = AsyncNotifierProvider<LocalSignatureNotifier, LocalSignatureState>(
  LocalSignatureNotifier.new,
);

/// Notifier chargeant le profil de l'utilisateur du téléphone.
///
/// Séparé de l'enregistrement (`SaveSignatureNotifier`) : un enregistrement en
/// cours ne doit pas faire repasser la page en chargement, ce qui détruirait
/// le formulaire en cours d'édition.
class LocalSignatureNotifier extends AsyncNotifier<LocalSignatureState> {
  /// Cas d'usage de lecture du profil local.
  late final _getLocalSignatureUsecase = ref.read(getLocalSignatureUsecaseProvider);

  @override
  Future<LocalSignatureState> build() async {
    final result = await _getLocalSignatureUsecase(const NoParams());
    return result.fold(
      onFailure: (GetLocalSignatureFailure failure) {
        final message = switch (failure) {
          GetLocalSignatureFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetLocalSignatureFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetLocalSignatureFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return LocalSignatureState(failureMessage: message);
      },
      onSuccess: (Signature? signature) => LocalSignatureState(signature: signature),
    );
  }

  /// Remplace le profil chargé par [signature], tout juste enregistré.
  ///
  /// Évite de relire le stockage (et de repasser par un état de chargement
  /// qui détruirait le formulaire) alors que le profil à jour est déjà connu.
  void setSignature(Signature signature) {
    state = AsyncData(LocalSignatureState(signature: signature));
  }
}

/// État du profil de l'utilisateur du téléphone.
class LocalSignatureState extends NotifierState {
  /// Crée un [LocalSignatureState].
  ///
  /// - [signature] : profil enregistré, `null` s'il n'a jamais été configuré.
  /// - [failureMessage] : message d'erreur éventuel.
  LocalSignatureState({this.signature, super.failureMessage});

  /// Profil enregistré, `null` s'il n'a jamais été configuré.
  final Signature? signature;
}
