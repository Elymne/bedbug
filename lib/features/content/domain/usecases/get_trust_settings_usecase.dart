import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/repositories/trust_settings_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_trust_settings_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetTrustSettingsUsecase].
final getTrustSettingsUsecaseProvider = Provider<GetTrustSettingsUsecase>((ref) {
  return GetTrustSettingsUsecase(ref.read(trustSettingsRepositoryProvider));
});

/// Récupère les réglages de confiance de l'utilisateur, ou les réglages par défaut s'il n'a rien modifié.
///
/// Chaque média, chaque lien affiché passe par ces réglages : ils décident
/// de ce que le téléphone a le droit de contacter. Les réglages par défaut
/// ne sont pas enregistrés tant que l'utilisateur n'a rien changé, pour
/// qu'une mise à jour des listes par défaut profite à ceux qui n'y ont pas
/// touché.
class GetTrustSettingsUsecase extends Usecase<NoParams, TrustSettingsFailure, TrustSettings> {
  /// Crée un [GetTrustSettingsUsecase].
  GetTrustSettingsUsecase(this._trustSettingsRepository);

  final TrustSettingsRepository _trustSettingsRepository;

  @override
  Future<Either<TrustSettingsFailure, TrustSettings>> call(NoParams params) async {
    try {
      return Right(await _trustSettingsRepository.get() ?? defaultTrustSettings);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetTrustSettingsUsecase', error, stackTrace);
      return const Left(TrustSettingsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetTrustSettingsUsecase', error, stackTrace);
      return const Left(TrustSettingsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetTrustSettingsUsecase', error, stackTrace);
      return const Left(TrustSettingsFailure.unknown);
    }
  }
}

/// Échecs possibles des use cases de lecture et d'écriture des réglages de confiance.
enum TrustSettingsFailure {
  /// Les réglages lus sont corrompus.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
