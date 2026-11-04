import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/usecases/content/get_own_contents/get_own_contents.failure.dart';
import 'package:bedbug/usecases/content/get_own_contents/get_own_contents.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [OwnContentsSectionNotifier].
///
/// `autoDispose` : la liste est relue à chaque ouverture de la section, pour
/// inclure les posts publiés entre-temps.
final ownContentsSectionNotifierProvider =
    AsyncNotifierProvider.autoDispose<OwnContentsSectionNotifier, OwnContentsSectionState>(
      OwnContentsSectionNotifier.new,
    );

/// Notifier chargeant les contenus publiés par l'utilisateur du téléphone, anonymes compris.
class OwnContentsSectionNotifier extends AsyncNotifier<OwnContentsSectionState> {
  /// Cas d'usage de récupération des contenus de l'utilisateur.
  late final _getOwnContentsUsecase = ref.read(getOwnContentsUsecaseProvider);

  @override
  Future<OwnContentsSectionState> build() async {
    final result = await _getOwnContentsUsecase(const NoParams());
    return result.fold(
      onFailure: (GetOwnContentsFailure failure) {
        final message = switch (failure) {
          GetOwnContentsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetOwnContentsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetOwnContentsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return OwnContentsSectionState(contents: const [], failureMessage: message);
      },
      onSuccess: (List<Content> contents) => OwnContentsSectionState(contents: contents),
    );
  }
}

/// État de la liste des contenus de l'utilisateur.
class OwnContentsSectionState extends NotifierState {
  /// Crée un [OwnContentsSectionState].
  ///
  /// - [contents] : contenus publiés par l'utilisateur, du plus récent au plus ancien.
  /// - [failureMessage] : message d'erreur éventuel.
  OwnContentsSectionState({required this.contents, super.failureMessage});

  /// Contenus publiés par l'utilisateur, du plus récent au plus ancien.
  final List<Content> contents;
}
