import 'dart:math' as math;

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/feed/recalculate_display_scores/recalculate_display_scores.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [RecalculateDisplayScoresUsecase].
final recalculateDisplayScoresUsecaseProvider = Provider<RecalculateDisplayScoresUsecase>((ref) {
  return RecalculateDisplayScoresUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Nombre de rebonds au-delà duquel le bonus de `bounce` n'augmente plus.
///
/// Plafonné pour qu'un contenu massivement (et potentiellement
/// artificiellement) rebondi ne puisse pas accumuler indéfiniment de bonus.
const int _bounceBonusCap = 10;

/// Poids maximum du bonus de `bounce` dans le `displayScore` final.
///
/// Volontairement faible : `bounce` n'est pas une donnée fiable (aucun
/// moyen de vérifier qu'un pair ne la falsifie pas), donc elle ne doit
/// jamais dominer la décroissance par ancienneté.
const double _bounceBonusWeight = 0.2;

/// Recalcule le `displayScore` de tous les contenus stockés localement.
///
/// La page d'accueil doit présenter les contenus les plus pertinents en
/// premier plutôt qu'un simple tri chronologique : un contenu qui a déjà
/// beaucoup circulé entre pairs a de bonnes chances d'intéresser
/// l'utilisateur, et l'origine du contenu influence la durée pendant
/// laquelle il mérite de rester mis en avant. Ce score doit donc être
/// recalculé périodiquement plutôt que figé à la création — ce use case est
/// le point d'entrée unique de ce recalcul, appelé par un job périodique.
///
/// Le score reste fixe à `1.0` pour [ContentOrigin.owned] : le contenu
/// publié par l'utilisateur reste toujours en tête de son propre fil. Pour
/// les autres provenances, il combine une décroissance exponentielle par
/// demi-vie (propre à chaque [ContentOrigin], intermédiaire entre celle du
/// `broadcastScore` et celle du `survivalScore`) et un bonus lié au nombre
/// de rebonds, signal d'intérêt indirect des pairs pour ce contenu.
///
/// Seules les colonnes des formules sont lues, et seule la colonne du score est réécrite, pour les seuls contenus
/// dont le score change : le recalcul tourne souvent, sur toute la base.
class RecalculateDisplayScoresUsecase extends Usecase<NoParams, RecalculateDisplayScoresFailure, void> {
  /// Crée un [RecalculateDisplayScoresUsecase].
  ///
  /// - [_contentRepository] : lecture des scores et écriture des nouveaux.
  /// - [_errorLogRepository] : journal des erreurs inattendues.
  RecalculateDisplayScoresUsecase(this._contentRepository, this._errorLogRepository);

  /// Lecture des scores et écriture des nouveaux.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Recalcule le score d'affichage de chaque contenu reçu et n'écrit que ceux qui changent, en une seule écriture.
  ///
  /// - [params] : aucun paramètre.
  @override
  Future<Either<RecalculateDisplayScoresFailure, void>> call(NoParams params) async {
    try {
      final summaries = await _contentRepository.getReceivedScoreSummaries();
      final now = DateTime.now();

      final updatedScores = <String, double>{};
      for (final summary in summaries) {
        if (summary.origin == ContentOrigin.owned) {
          continue;
        }

        final ageDays = now.difference(summary.createdAt).inHours / 24;
        final halfLife = summary.origin.displayHalfLifeDays;
        final ageScore = math.pow(0.5, ageDays / halfLife).toDouble();

        // Bonus volontairement modeste : `bounce` n'est pas vérifiable côté appareil
        // (rien n'empêche un pair de le falsifier), il ne doit donc influencer le
        // score qu'à la marge, jamais suffire seul à faire remonter un contenu
        // autrement condamné par son ancienneté.
        final bounceBonus = _bounceBonusWeight * (math.min(summary.bounce, _bounceBonusCap) / _bounceBonusCap);
        final newScore = (ageScore + bounceBonus).clamp(0.0, 1.0);

        if (newScore == summary.displayScore) {
          continue;
        }

        updatedScores[summary.contentId] = newScore;
      }

      await _contentRepository.updateDisplayScores(updatedScores);

      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('RecalculateDisplayScoresUsecase', error, stackTrace);
      return const Left(RecalculateDisplayScoresFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('RecalculateDisplayScoresUsecase', error, stackTrace);
      return const Left(RecalculateDisplayScoresFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('RecalculateDisplayScoresUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'RecalculateDisplayScoresUsecase', error: error, stackTrace: stackTrace);
      return const Left(RecalculateDisplayScoresFailure.unknown);
    }
  }
}
