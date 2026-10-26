import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [CreateNotifier].
///
/// `autoDispose` : l'état repart de zéro à chaque ouverture de la page, ce qui
/// relit aussi le réglage « anonyme par défaut » s'il a changé entre-temps.
final createNotifierProvider = AsyncNotifierProvider.autoDispose<CreateNotifier, CreateState>(CreateNotifier.new);

/// Notifier gérant l'état du formulaire de la page de création de contenu : le type choisi et le réglage anonyme.
///
/// La publication elle-même est gérée à part, par `PublishContentNotifier` :
/// son chargement, long quand il faut compresser des images, ne doit pas
/// faire disparaître le formulaire.
class CreateNotifier extends AsyncNotifier<CreateState> {
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
}

/// État du formulaire de la page de création de contenu.
class CreateState {
  /// Crée un [CreateState].
  ///
  /// - [selectedType] : type de contenu actuellement sélectionné.
  /// - [isAnonymousByDefault] : `true` si la case « publier en anonyme » doit partir cochée.
  const CreateState({required this.selectedType, this.isAnonymousByDefault = false});

  /// Type de contenu actuellement sélectionné dans le toggle.
  final ContentType selectedType;

  /// Indique si la case « publier en anonyme » doit partir cochée, d'après les réglages.
  final bool isAnonymousByDefault;

  /// Retourne une copie du state avec les champs modifiés fournis.
  CreateState copyWith({ContentType? selectedType}) {
    return CreateState(selectedType: selectedType ?? this.selectedType, isAnonymousByDefault: isAnonymousByDefault);
  }
}
