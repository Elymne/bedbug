import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.entity.dart';
import 'package:bedbug/usecases/settings/save_settings/save_settings.usecase.dart';

/// Paramètres du [SaveSettingsUsecase].
class SaveSettingsParams extends Params {
  /// Crée des [SaveSettingsParams].
  ///
  /// - [settings] : settings à persister.
  const SaveSettingsParams({required this.settings});

  /// Settings à persister.
  final UserSettings settings;
}
