import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_own_contents_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [OwnContentsNotifier].
///
/// `autoDispose` : la liste est relue à chaque ouverture de la section, pour
/// inclure les posts publiés entre-temps.
final ownContentsNotifierProvider = AsyncNotifierProvider.autoDispose<OwnContentsNotifier, OwnContentsState>(
  OwnContentsNotifier.new,
);

/// Notifier chargeant les contenus publiés par l'utilisateur du téléphone, anonymes compris.
class OwnContentsNotifier extends AsyncNotifier<OwnContentsState> {
  /// Cas d'usage de récupération des contenus de l'utilisateur.
  late final _getOwnContentsUsecase = ref.read(getOwnContentsUsecaseProvider);

  @override
  Future<OwnContentsState> build() async {
    final result = await _getOwnContentsUsecase(const NoParams());
    return result.fold(
      onFailure: (GetOwnContentsFailure failure) {
        final message = switch (failure) {
          GetOwnContentsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetOwnContentsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetOwnContentsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return OwnContentsState(contents: const [], failureMessage: message);
      },
      onSuccess: (List<Content> contents) => OwnContentsState(contents: contents),
    );
  }
}

/// État de la liste des contenus de l'utilisateur.
class OwnContentsState extends NotifierState {
  /// Crée un [OwnContentsState].
  ///
  /// - [contents] : contenus publiés par l'utilisateur, du plus récent au plus ancien.
  /// - [failureMessage] : message d'erreur éventuel.
  OwnContentsState({required this.contents, super.failureMessage});

  /// Contenus publiés par l'utilisateur, du plus récent au plus ancien.
  final List<Content> contents;
}
