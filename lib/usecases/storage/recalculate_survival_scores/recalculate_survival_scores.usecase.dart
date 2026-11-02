import 'dart:math' as math;

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/storage/recalculate_survival_scores/recalculate_survival_scores.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [RecalculateSurvivalScoresUsecase].
final recalculateSurvivalScoresUsecaseProvider = Provider<RecalculateSurvivalScoresUsecase>((ref) {
  return RecalculateSurvivalScoresUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Nombre de rebonds au-delà duquel le bonus de `bounce` n'augmente plus.
///
/// Plafonné pour qu'un contenu massivement (et potentiellement
/// artificiellement) rebondi ne puisse pas accumuler indéfiniment de bonus.
const int _bounceBonusCap = 10;

/// Poids maximum du bonus de `bounce` dans le `survivalScore` final.
///
/// Volontairement faible : `bounce` n'est pas une donnée fiable (aucun
/// moyen de vérifier qu'un pair ne la falsifie pas), donc elle ne doit
/// jamais dominer la décroissance par ancienneté.
const double _bounceBonusWeight = 0.2;

/// Recalcule le `survivalScore` de tous les contenus stockés localement.
///
/// Le stockage de l'appareil est limité : on doit pouvoir décider quels
/// contenus supprimer en premier lors d'un nettoyage automatique, sans
/// jamais perdre les contenus les plus précieux pour l'utilisateur (les
/// siens, ses favoris). Comme la valeur perçue d'un contenu change avec le
/// temps (il vieillit) et avec son usage (il peut être rebondi vers
/// d'autres appareils), ce score doit être recalculé périodiquement plutôt
/// que figé à la création — ce use case est le point d'entrée unique de ce
/// recalcul, appelé par un job périodique.
///
/// Le score reste fixe à `1.0` pour [ContentOrigin.owned]. Pour les autres
/// provenances, il combine une décroissance exponentielle par demi-vie
/// (propre à chaque [ContentOrigin]) et un bonus lié au nombre de rebonds.
class RecalculateSurvivalScoresUsecase extends Usecase<NoParams, RecalculateSurvivalScoresFailure, void> {
  /// Crée un [RecalculateSurvivalScoresUsecase].
  RecalculateSurvivalScoresUsecase(this._contentRepository, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<RecalculateSurvivalScoresFailure, void>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAll();
      final now = DateTime.now();

      final updated = <Content>[];
      for (final content in contents) {
        if (content.origin == ContentOrigin.owned) {
          continue;
        }

        final ageDays = now.difference(content.createdAt).inHours / 24;
        final halfLife = content.origin.survivalHalfLifeDays;
        final ageScore = math.pow(0.5, ageDays / halfLife).toDouble();

        // Bonus volontairement modeste : `bounce` n'est pas vérifiable côté appareil
        // (rien n'empêche un pair de le falsifier), il ne doit donc influencer le
        // score qu'à la marge, jamais suffire seul à sauver un contenu autrement
        // condamné par son ancienneté.
        final bounceBonus = _bounceBonusWeight * (math.min(content.bounce, _bounceBonusCap) / _bounceBonusCap);
        final newScore = (ageScore + bounceBonus).clamp(0.0, 1.0);

        if (newScore == content.survivalScore) {
          continue;
        }

        updated.add(content.copyWithScores(survivalScore: newScore));
      }

      if (updated.isNotEmpty) {
        await _contentRepository.updateMany(updated);
      }

      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('RecalculateSurvivalScoresUsecase', error, stackTrace);
      return const Left(RecalculateSurvivalScoresFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('RecalculateSurvivalScoresUsecase', error, stackTrace);
      return const Left(RecalculateSurvivalScoresFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('RecalculateSurvivalScoresUsecase', error, stackTrace);
      await _errorLogRepository.record(
        source: 'RecalculateSurvivalScoresUsecase',
        error: error,
        stackTrace: stackTrace,
      );
      return const Left(RecalculateSurvivalScoresFailure.unknown);
    }
  }
}
