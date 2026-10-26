import 'dart:math';

import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentReactionsUsecase].
final getContentReactionsUsecaseProvider = Provider<GetContentReactionsUsecase>((ref) {
  return GetContentReactionsUsecase(ref.read(reactionRepositoryProvider), Random());
});

/// Retourne les réactions d'un contenu, dans un ordre aléatoire.
///
/// Les réactions sont stockées à part du contenu (elles voyagent seules
/// entre pairs) : la page de détail doit donc les charger séparément. Elles
/// sont mélangées plutôt que triées : sans classement, aucune réaction n'est
/// favorisée par sa date ou son auteur, et chaque visite en met d'autres en
/// avant.
class GetContentReactionsUsecase
    extends Usecase<GetContentReactionsParams, GetContentReactionsFailure, List<Reaction>> {
  /// Crée un [GetContentReactionsUsecase].
  GetContentReactionsUsecase(this._reactionRepository, this._random);

  final ReactionRepository _reactionRepository;
  final Random _random;

  @override
  Future<Either<GetContentReactionsFailure, List<Reaction>>> call(GetContentReactionsParams params) async {
    try {
      final reactions = await _reactionRepository.getAllByContentId(params.contentId);
      return Right(reactions..shuffle(_random));
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentReactionsUsecase', error, stackTrace);
      return const Left(GetContentReactionsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentReactionsUsecase', error, stackTrace);
      return const Left(GetContentReactionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentReactionsUsecase', error, stackTrace);
      return const Left(GetContentReactionsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetContentReactionsUsecase].
enum GetContentReactionsFailure {
  /// Une réaction stockée est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture.
  unknown,
}

/// Paramètres du [GetContentReactionsUsecase].
class GetContentReactionsParams extends Params {
  /// Crée des [GetContentReactionsParams].
  ///
  /// - [contentId] : identifiant du contenu dont on veut les réactions.
  const GetContentReactionsParams({required this.contentId});

  /// Identifiant du contenu dont on veut les réactions.
  final String contentId;
}
