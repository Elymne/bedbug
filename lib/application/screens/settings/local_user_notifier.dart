import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/usecases/get_local_user_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [LocalUserNotifier].
final localUserNotifierProvider = AsyncNotifierProvider<LocalUserNotifier, LocalUserState>(LocalUserNotifier.new);

/// Notifier chargeant le profil de l'utilisateur du téléphone.
///
/// Séparé de l'enregistrement (`SaveProfileNotifier`) : un enregistrement en
/// cours ne doit pas faire repasser la page en chargement, ce qui détruirait
/// le formulaire en cours d'édition.
class LocalUserNotifier extends AsyncNotifier<LocalUserState> {
  /// Cas d'usage de lecture du profil local.
  late final _getLocalUserUsecase = ref.read(getLocalUserUsecaseProvider);

  @override
  Future<LocalUserState> build() async {
    final result = await _getLocalUserUsecase(const NoParams());
    return result.fold(
      onFailure: (GetLocalUserFailure failure) {
        final message = switch (failure) {
          GetLocalUserFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetLocalUserFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetLocalUserFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return LocalUserState(failureMessage: message);
      },
      onSuccess: (User? user) => LocalUserState(user: user),
    );
  }

  /// Remplace le profil chargé par [user], tout juste enregistré.
  ///
  /// Évite de relire le stockage (et de repasser par un état de chargement
  /// qui détruirait le formulaire) alors que le profil à jour est déjà connu.
  void setUser(User user) {
    state = AsyncData(LocalUserState(user: user));
  }
}

/// État du profil de l'utilisateur du téléphone.
class LocalUserState extends NotifierState {
  /// Crée un [LocalUserState].
  ///
  /// - [user] : profil enregistré, `null` s'il n'a jamais été configuré.
  /// - [failureMessage] : message d'erreur éventuel.
  LocalUserState({this.user, super.failureMessage});

  /// Profil enregistré, `null` s'il n'a jamais été configuré.
  final User? user;
}
