import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [CountContentReactionsUsecase].
final countContentReactionsUsecaseProvider = Provider<CountContentReactionsUsecase>((ref) {
  return CountContentReactionsUsecase(ref.read(reactionRepositoryProvider));
});

/// Compte les réactions d'un contenu, sans les charger.
///
/// Le nombre de réactions est affiché en tag à côté des bounces, jusque
/// dans les tuiles du fil : y charger toutes les réactions de chaque contenu
/// visible, juste pour les compter, serait du gaspillage.
class CountContentReactionsUsecase extends Usecase<CountContentReactionsParams, CountContentReactionsFailure, int> {
  /// Crée un [CountContentReactionsUsecase].
  CountContentReactionsUsecase(this._reactionRepository);

  final ReactionRepository _reactionRepository;

  @override
  Future<Either<CountContentReactionsFailure, int>> call(CountContentReactionsParams params) async {
    try {
      return Right(await _reactionRepository.countByContentId(params.contentId));
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('CountContentReactionsUsecase', error, stackTrace);
      return const Left(CountContentReactionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('CountContentReactionsUsecase', error, stackTrace);
      return const Left(CountContentReactionsFailure.unknown);
    }
  }
}

/// Échecs possibles du [CountContentReactionsUsecase].
enum CountContentReactionsFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du comptage.
  unknown,
}

/// Paramètres du [CountContentReactionsUsecase].
class CountContentReactionsParams extends Params {
  /// Crée des [CountContentReactionsParams].
  ///
  /// - [contentId] : identifiant du contenu dont on compte les réactions.
  const CountContentReactionsParams({required this.contentId});

  /// Identifiant du contenu dont on compte les réactions.
  final String contentId;
}
