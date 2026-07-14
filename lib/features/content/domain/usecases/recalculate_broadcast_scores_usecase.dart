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

/// Provider du [RecalculateBroadcastScoresUsecase].
final recalculateBroadcastScoresUsecaseProvider = Provider<RecalculateBroadcastScoresUsecase>(
  (ref) => RecalculateBroadcastScoresUsecase(ref.read(contentRepositoryProvider)),
);

/// Nombre de rebonds au-delà duquel la pénalité de `bounce` n'augmente plus.
///
/// Plafonnée pour qu'un contenu massivement (et potentiellement
/// artificiellement) rebondi ne voie pas sa priorité de diffusion tomber à
/// zéro dès les premiers rebonds constatés.
const int _bouncePenaltyCap = 10;

/// Poids maximum de la pénalité de `bounce` dans le `broadcastScore` final.
///
/// Volontairement faible : `bounce` n'est pas une donnée fiable (aucun
/// moyen de vérifier qu'un pair ne la falsifie pas), donc elle ne doit
/// jamais dominer la décroissance par ancienneté.
const double _bouncePenaltyWeight = 0.2;

/// Recalcule le `broadcastScore` de tous les contenus stockés localement.
///
/// La bande passante BLE/WIFI disponible pour diffuser des contenus est
/// limitée : on doit pouvoir décider quels contenus envoyer en priorité aux
/// pairs à proximité. Contrairement à `survivalScore` (qui répond à une
/// notion de valeur perçue s'érodant lentement), la priorité de diffusion
/// répond à une fenêtre de propagation qui se referme vite : un contenu
/// fraîchement reçu doit être poussé pendant qu'il est « chaud », puis
/// laisser la place à d'autres contenus une fois qu'il a déjà largement
/// circulé. Ce score doit donc être recalculé périodiquement plutôt que
/// figé à la création — ce use case est le point d'entrée unique de ce
/// recalcul, appelé par un job périodique.
///
/// Le score reste fixe à `1.0` pour [ContentOrigin.owned] : un contenu créé
/// par l'utilisateur doit toujours être diffusé en priorité, quel que soit
/// son âge. Pour les autres provenances, il combine une décroissance
/// exponentielle par demi-vie (propre à chaque [ContentOrigin], bien plus
/// courte que celle du `survivalScore`) et une pénalité liée au nombre de
/// rebonds : plus un contenu a déjà circulé, moins il est utile de
/// continuer à le pousser activement.
class RecalculateBroadcastScoresUsecase extends Usecase<NoParams, RecalculateBroadcastScoresFailure, void> {
  /// Crée un [RecalculateBroadcastScoresUsecase].
  RecalculateBroadcastScoresUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<RecalculateBroadcastScoresFailure, void>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAll();
      final now = DateTime.now();

      final updated = <Content>[];
      for (final content in contents) {
        if (content.origin == ContentOrigin.owned) {
          continue;
        }

        final ageDays = now.difference(content.createdAt).inHours / 24;
        final halfLife = content.origin.broadcastHalfLifeDays;
        final ageScore = math.pow(0.5, ageDays / halfLife).toDouble();

        // Pénalité volontairement modeste : `bounce` n'est pas vérifiable côté appareil
        // (rien n'empêche un pair de le falsifier), elle ne doit donc influencer le
        // score qu'à la marge, jamais suffire seule à faire tomber la priorité d'un
        // contenu par ailleurs encore frais à zéro.
        final bouncePenalty = _bouncePenaltyWeight * (math.min(content.bounce, _bouncePenaltyCap) / _bouncePenaltyCap);
        final newScore = (ageScore - bouncePenalty).clamp(0.0, 1.0);

        if (newScore == content.broadcastScore) {
          continue;
        }

        updated.add(content.copyWithScores(broadcastScore: newScore));
      }

      if (updated.isNotEmpty) {
        await _contentRepository.updateMany(updated);
      }

      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('RecalculateBroadcastScoresUsecase', error, stackTrace);
      return const Left(RecalculateBroadcastScoresFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('RecalculateBroadcastScoresUsecase', error, stackTrace);
      return const Left(RecalculateBroadcastScoresFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('RecalculateBroadcastScoresUsecase', error, stackTrace);
      return const Left(RecalculateBroadcastScoresFailure.unknown);
    }
  }
}

/// Échecs possibles du [RecalculateBroadcastScoresUsecase].
enum RecalculateBroadcastScoresFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul des scores.
  unknown,
}
