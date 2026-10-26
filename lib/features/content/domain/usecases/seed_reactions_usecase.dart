import 'dart:math';

import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SeedReactionsUsecase].
final seedReactionsUsecaseProvider = Provider<SeedReactionsUsecase>((ref) {
  return SeedReactionsUsecase(ref.read(contentRepositoryProvider), ref.read(reactionRepositoryProvider));
});

/// Bedbugs factices, tous conformes à la règle des icônes (pas de mot).
const List<String> _avatarTexts = [
  '(◕‿◕)',
  'ʕ•ᴥ•ʔ',
  '(=^･ω･^=)',
  '(╯°□°)╯︵ ┻━┻',
  r'¯\_(ツ)_/¯',
  '(ง •̀_•́)ง',
  '(づ｡◕‿‿◕｡)づ',
  '(-.-)Zzz',
  '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
  '(ಥ﹏ಥ)',
  '(⊙_⊙)',
  '♪~ ᕕ(ᐛ)ᕗ',
];

/// Bulles factices, de l'interjection à la longueur maximale autorisée (40 caractères).
const List<String> _bubbleTexts = [
  'mdr',
  'ok',
  'trop bien',
  'non mais allô',
  'je valide à 100 %',
  'ça m\'a tué',
  'qui a demandé ?',
  'je ne m\'y attendais pas du tout là',
  'quarante caractères pile pour tester ok',
];

/// Couleurs de ghost factices, en ARGB 32 bits.
const List<int> _colorArgbs = [0xFFFF7DA4, 0xFF51C2FF, 0xFF9BDDB1, 0xFF9B59B6, 0xFFFF9D4D, 0xFFFFD166];

/// Génère des réactions factices sur les premiers contenus du fil, pour tester le poids et la charge de l'affichage.
///
/// Les réactions sont posées sur les [SeedReactionsParams.contentCount]
/// premiers contenus dans l'ordre du fil de la page d'accueil : ce sont ceux
/// que l'on ouvre en premier en testant. Chaque contenu reçoit
/// [SeedReactionsParams.reactionsPerContent] réactions d'auteurs factices tous
/// différents (une réaction par signature et par contenu), avec un bedbug,
/// une couleur, une intensité et une bulle tirés au
/// hasard. Écrites directement dans le repository, par lots, comme les
/// contenus factices : passer par le use case d'enregistrement, réaction par
/// réaction, rendrait le seed beaucoup trop lent.
class SeedReactionsUsecase extends Usecase<SeedReactionsParams, SeedReactionsFailure, void> {
  /// Crée un [SeedReactionsUsecase].
  SeedReactionsUsecase(this._contentRepository, this._reactionRepository);

  final ContentRepository _contentRepository;
  final ReactionRepository _reactionRepository;

  @override
  Future<Either<SeedReactionsFailure, void>> call(SeedReactionsParams params) async {
    try {
      final random = Random(params.randomSeed);
      final now = DateTime.now();
      final reactionsPerContent = min(params.reactionsPerContent, maxReactionsPerContent);
      final contents = (await _contentRepository.getAllOrderedByDisplayScoreDesc()).take(params.contentCount);

      for (final content in contents) {
        final reactions = [
          for (var index = 0; index < reactionsPerContent; index++)
            _buildReaction(random, content.id, 'seed-reactor-$index', now.subtract(Duration(minutes: index))),
        ];
        await _reactionRepository.addMany(reactions);
      }
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SeedReactionsUsecase', error, stackTrace);
      return const Left(SeedReactionsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SeedReactionsUsecase', error, stackTrace);
      return const Left(SeedReactionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SeedReactionsUsecase', error, stackTrace);
      return const Left(SeedReactionsFailure.unknown);
    }
  }

  /// Construit une réaction factice de [authorId] sur [contentId], aux réglages tirés au hasard.
  ///
  /// - [random] : générateur partagé par tout le seed.
  /// - [contentId] : contenu auquel la réaction est rattachée.
  /// - [authorId] : auteur factice de la réaction.
  /// - [date] : date de création et de mise à jour de la réaction.
  Reaction _buildReaction(Random random, String contentId, String authorId, DateTime date) {
    final steps = ((maxGhostSpeed - minGhostSpeed) / 0.25).round();
    return Reaction(
      id: UuidX.generate(),
      createdAt: date,
      updatedAt: date,
      contentId: contentId,
      authorId: authorId,
      avatarText: _avatarTexts[random.nextInt(_avatarTexts.length)],
      bubbleText: _bubbleTexts[random.nextInt(_bubbleTexts.length)],
      colorArgb: _colorArgbs[random.nextInt(_colorArgbs.length)],
      ghostSpeed: minGhostSpeed + random.nextInt(steps + 1) * 0.25,
    );
  }
}

/// Échecs possibles du [SeedReactionsUsecase].
enum SeedReactionsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la génération.
  unknown,
}

/// Paramètres du [SeedReactionsUsecase].
class SeedReactionsParams extends Params {
  /// Crée des [SeedReactionsParams].
  ///
  /// - [contentCount] : nombre de contenus, en tête du fil, qui reçoivent des réactions. Par défaut : 200.
  /// - [reactionsPerContent] : nombre de réactions par contenu, plafonné à [maxReactionsPerContent]. Par défaut : 100.
  /// - [randomSeed] : graine du tirage, pour un seed reproductible (tests). `null` pour un tirage aléatoire.
  const SeedReactionsParams({this.contentCount = 200, this.reactionsPerContent = 100, this.randomSeed});

  /// Nombre de contenus, en tête du fil, qui reçoivent des réactions.
  final int contentCount;

  /// Nombre de réactions par contenu.
  final int reactionsPerContent;

  /// Graine du tirage, `null` pour un tirage aléatoire.
  final int? randomSeed;
}
