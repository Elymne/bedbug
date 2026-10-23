import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [CreateNotifier].
///
/// `autoDispose` : l'état repart de zéro à chaque ouverture de la page, ce qui
/// relit aussi le réglage « anonyme par défaut » s'il a changé entre-temps.
final createNotifierProvider = AsyncNotifierProvider.autoDispose<CreateNotifier, CreateState>(CreateNotifier.new);

/// Notifier gérant l'état de la page de création de contenu.
class CreateNotifier extends AsyncNotifier<CreateState> {
  /// Cas d'usage de sauvegarde d'un contenu.
  late final _saveUsecase = ref.read(saveContentUsecaseProvider);

  /// Cas d'usage de lecture des réglages, pour la publication anonyme par défaut.
  late final _getSettingsUsecase = ref.read(getSettingsUsecaseProvider);

  @override
  Future<CreateState> build() async {
    final result = await _getSettingsUsecase(const NoParams());
    // Des réglages illisibles ne bloquent pas la création : la case
    // « anonyme » part simplement décochée.
    final isAnonymousByDefault = result.right?.isAnonymousByDefault ?? false;
    return CreateState(selectedType: ContentType.text, isAnonymousByDefault: isAnonymousByDefault);
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
    final current = state.requireValue;
    state = const AsyncLoading();

    final result = await _saveUsecase(SaveContentParams(content: content));
    result.fold(
      onFailure: (SaveContentFailure failure) {
        final message = switch (failure) {
          SaveContentFailure.storageError => ref.l10n.homeGetContentsStorageError,
          SaveContentFailure.unknown => ref.l10n.createSaveError,
        };
        state = AsyncData(current.copyWith(failureMessage: message));
      },
      onSuccess: (_) {
        state = AsyncData(current.copyWith(isSuccess: true));
      },
    );
  }
}

/// État de la page de création de contenu.
class CreateState {
  /// Crée un [CreateState].
  ///
  /// - [selectedType] : type de contenu actuellement sélectionné.
  /// - [isAnonymousByDefault] : `true` si la case « publier en anonyme » doit partir cochée.
  /// - [failureMessage] : message d'erreur éventuel après une tentative de sauvegarde.
  /// - [isSuccess] : `true` si la sauvegarde vient de réussir.
  const CreateState({
    required this.selectedType,
    this.isAnonymousByDefault = false,
    this.failureMessage,
    this.isSuccess = false,
  });

  /// Type de contenu actuellement sélectionné dans le toggle.
  final ContentType selectedType;

  /// Indique si la case « publier en anonyme » doit partir cochée, d'après les réglages.
  final bool isAnonymousByDefault;

  /// Message d'erreur après un échec de sauvegarde. `null` si aucun échec.
  final String? failureMessage;

  /// Indique si la sauvegarde vient de réussir.
  final bool isSuccess;

  /// Retourne une copie du state avec les champs modifiés fournis.
  ///
  /// [failureMessage] et [isSuccess] ne sont pas conservés : ils décrivent le
  /// résultat d'une seule tentative de sauvegarde.
  CreateState copyWith({ContentType? selectedType, String? failureMessage, bool? isSuccess}) {
    return CreateState(
      selectedType: selectedType ?? this.selectedType,
      isAnonymousByDefault: isAnonymousByDefault,
      failureMessage: failureMessage,
      isSuccess: isSuccess ?? false,
    );
  }
}
