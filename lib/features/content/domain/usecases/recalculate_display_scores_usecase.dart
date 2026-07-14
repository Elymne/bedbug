import 'dart:math' as math;

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [RecalculateDisplayScoresUsecase].
final recalculateDisplayScoresUsecaseProvider = Provider<RecalculateDisplayScoresUsecase>(
  (ref) => RecalculateDisplayScoresUsecase(ref.read(contentRepositoryProvider)),
);

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
class RecalculateDisplayScoresUsecase extends Usecase<NoParams, RecalculateDisplayScoresFailure, void> {
  /// Crée un [RecalculateDisplayScoresUsecase].
  RecalculateDisplayScoresUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<RecalculateDisplayScoresFailure, void>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAll();
      final now = DateTime.now();

      final updated = <Content>[];
      for (final content in contents) {
        if (content.origin == ContentOrigin.owned) {
          continue;
        }

        final ageDays = now.difference(content.createdAt).inHours / 24;
        final halfLife = content.origin.displayHalfLifeDays;
        final ageScore = math.pow(0.5, ageDays / halfLife).toDouble();

        // Bonus volontairement modeste : `bounce` n'est pas vérifiable côté appareil
        // (rien n'empêche un pair de le falsifier), il ne doit donc influencer le
        // score qu'à la marge, jamais suffire seul à faire remonter un contenu
        // autrement condamné par son ancienneté.
        final bounceBonus = _bounceBonusWeight * (math.min(content.bounce, _bounceBonusCap) / _bounceBonusCap);
        final newScore = (ageScore + bounceBonus).clamp(0.0, 1.0);

        if (newScore == content.displayScore) {
          continue;
        }

        updated.add(content.copyWithScores(displayScore: newScore));
      }

      if (updated.isNotEmpty) {
        await _contentRepository.updateMany(updated);
      }

      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('RecalculateDisplayScoresUsecase', error, stackTrace);
      return const Left(RecalculateDisplayScoresFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('RecalculateDisplayScoresUsecase', error, stackTrace);
      return const Left(RecalculateDisplayScoresFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('RecalculateDisplayScoresUsecase', error, stackTrace);
      return const Left(RecalculateDisplayScoresFailure.unknown);
    }
  }
}

/// Échecs possibles du [RecalculateDisplayScoresUsecase].
enum RecalculateDisplayScoresFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul des scores.
  unknown,
}
