import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [CreateNotifier].
final createNotifierProvider = AsyncNotifierProvider<CreateNotifier, CreateState>(CreateNotifier.new);

/// Notifier gérant l'état de la page de création de contenu.
class CreateNotifier extends AsyncNotifier<CreateState> {
  /// Cas d'usage de sauvegarde d'un contenu.
  late final _saveUsecase = ref.read(saveContentUsecaseProvider);

  @override
  Future<CreateState> build() async {
    return const CreateState(selectedType: ContentType.text);
  }

  /// Met à jour le type de contenu sélectionné.
  ///
  /// - [type] : nouveau type à sélectionner.
  void setType(ContentType type) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(selectedType: type));
  }

  /// Sauvegarde le [content] fourni dans le stockage local.
  Future<void> save(Content content) async {
    final currentType = state.requireValue.selectedType;
    state = const AsyncLoading();

    final result = await _saveUsecase(SaveContentParams(content: content));
    result.fold(
      onFailure: (SaveContentFailure failure) {
        final message = switch (failure) {
          SaveContentFailure.storageError => ref.l10n.homeGetContentsStorageError,
          SaveContentFailure.unknown => ref.l10n.createSaveError,
        };
        state = AsyncData(
          CreateState(selectedType: currentType, failureMessage: message),
        );
      },
      onSuccess: (_) {
        state = AsyncData(
          CreateState(selectedType: currentType, isSuccess: true),
        );
      },
    );
  }
}

/// État de la page de création de contenu.
class CreateState {
  /// Crée un [CreateState].
  ///
  /// - [selectedType] : type de contenu actuellement sélectionné.
  /// - [failureMessage] : message d'erreur éventuel après une tentative de sauvegarde.
  /// - [isSuccess] : `true` si la sauvegarde vient de réussir.
  const CreateState({
    required this.selectedType,
    this.failureMessage,
    this.isSuccess = false,
  });

  /// Type de contenu actuellement sélectionné dans le toggle.
  final ContentType selectedType;

  /// Message d'erreur après un échec de sauvegarde. `null` si aucun échec.
  final String? failureMessage;

  /// Indique si la sauvegarde vient de réussir.
  final bool isSuccess;

  /// Retourne une copie du state avec les champs modifiés fournis.
  CreateState copyWith({
    ContentType? selectedType,
    String? failureMessage,
    bool? isSuccess,
  }) {
    return CreateState(
      selectedType: selectedType ?? this.selectedType,
      failureMessage: failureMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
