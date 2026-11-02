import 'dart:math';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/reaction.entity.dart';
import 'package:bedbug/resources/content/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/reaction/get_content_reactions/get_content_reactions.failure.dart';
import 'package:bedbug/usecases/reaction/get_content_reactions/get_content_reactions.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentReactionsUsecase].
final getContentReactionsUsecaseProvider = Provider<GetContentReactionsUsecase>((ref) {
  return GetContentReactionsUsecase(
    ref.read(reactionRepositoryProvider),
    Random(),
    ref.read(errorLogRepositoryProvider),
  );
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
  GetContentReactionsUsecase(this._reactionRepository, this._random, this._errorLogRepository);

  final ReactionRepository _reactionRepository;
  final Random _random;
  final ErrorLogRepository _errorLogRepository;

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
      await _errorLogRepository.record(source: 'GetContentReactionsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetContentReactionsFailure.unknown);
    }
  }
}
