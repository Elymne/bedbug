import 'dart:math' as math;

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/extensions/content_origin_x.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [RecalculateSurvivalScoresUsecase].
final recalculateSurvivalScoresUsecaseProvider = Provider<RecalculateSurvivalScoresUsecase>(
  (ref) => RecalculateSurvivalScoresUsecase(ref.read(contentRepositoryProvider)),
);

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
  RecalculateSurvivalScoresUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<RecalculateSurvivalScoresFailure, void>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAll();
      final now = DateTime.now();

      final updated = <Content>[];
      for (final content in contents) {
        if (content.origin == ContentOrigin.owned) continue;

        final newScore = _computeSurvivalScore(content, now);
        if (newScore == content.survivalScore) continue;

        updated.add(content.copyWithScores(survivalScore: newScore));
      }

      if (updated.isNotEmpty) await _contentRepository.updateMany(updated);

      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('RecalculateSurvivalScoresUsecase', error, stackTrace);
      return const Left(RecalculateSurvivalScoresFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('RecalculateSurvivalScoresUsecase', error, stackTrace);
      return const Left(RecalculateSurvivalScoresFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('RecalculateSurvivalScoresUsecase', error, stackTrace);
      return const Left(RecalculateSurvivalScoresFailure.unknown);
    }
  }

  /// Combine la décroissance par ancienneté et le bonus de rebonds pour
  /// produire le nouveau `survivalScore` de [content] à l'instant [now].
  ///
  /// Le bonus de rebonds reste volontairement modeste (plafonné à `+0.2`) :
  /// `bounce` n'est pas vérifiable côté appareil (rien n'empêche un pair de
  /// le falsifier), donc il ne doit influencer le score qu'à la marge et
  /// jamais suffire, seul, à sauver un contenu autrement condamné par son
  /// ancienneté.
  double _computeSurvivalScore(Content content, DateTime now) {
    final ageDays = now.difference(content.createdAt).inHours / 24;
    final halfLife = content.origin.survivalHalfLifeDays;
    final ageScore = math.pow(0.5, ageDays / halfLife).toDouble();

    final bounceBonus = _bounceBonusWeight * (math.min(content.bounce, _bounceBonusCap) / _bounceBonusCap);

    return (ageScore + bounceBonus).clamp(0.0, 1.0);
  }
}

/// Échecs possibles du [RecalculateSurvivalScoresUsecase].
enum RecalculateSurvivalScoresFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul des scores.
  unknown,
}
