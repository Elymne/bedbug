import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/gateways/exchange/exchange_codec/exchange_codec.config.dart';
import 'package:bedbug/infra/gateways/exchange/exchange_codec/exchange_codec.gateway.dart';
import 'package:bedbug/infra/gateways/exchange/exchange_codec/exchange_codec.gateway.json_zlib.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.summary.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/exchange/build_exchange_offer/build_exchange_offer.config.dart';
import 'package:bedbug/logic/usecases/exchange/build_exchange_offer/build_exchange_offer.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [BuildExchangeOfferUsecase].
final buildExchangeOfferUsecaseProvider = Provider<BuildExchangeOfferUsecase>((ref) {
  return BuildExchangeOfferUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(exchangeCodecGatewayProvider),
    Random(),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Construit l'offre envoyée à un pair au début d'un échange, déjà encodée pour le transport.
///
/// Un échange commence par proposer, pas par envoyer : on ne connaît pas encore ce que le pair possède, et
/// pousser des contenus à l'aveugle gaspillerait une bande passante BLE rare (quelques dizaines de Ko/s). L'offre
/// liste donc les [priorityOfferedContents] contenus de plus fort `broadcastScore` (les plus « chauds », et toujours
/// ceux de l'utilisateur), du plus prioritaire au moins prioritaire, complétés au hasard jusqu'à
/// [maxOfferedContents], pour que les autres contenus aient leur chance. Pour chacun, elle résume ses réactions
/// (nombre, date de la plus récente) : un pair qui possède déjà le contenu peut ainsi ne demander que les
/// réactions qui lui manquent.
class BuildExchangeOfferUsecase extends Usecase<NoParams, BuildExchangeOfferFailure, Uint8List> {
  /// Crée un [BuildExchangeOfferUsecase].
  BuildExchangeOfferUsecase(
    this._contentRepository,
    this._exchangeCodecGateway,
    this._random,
    this._errorLogRepository,
  );

  /// Repository des contenus, qui fournit leurs résumés.
  final ContentRepository _contentRepository;

  /// Codec des messages d'échange.
  final ExchangeCodecGateway _exchangeCodecGateway;

  /// Générateur du tirage des contenus complétant l'offre.
  final Random _random;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<BuildExchangeOfferFailure, Uint8List>> call(NoParams params) async {
    try {
      final priorityContents = await _contentRepository.getTopSummariesByBroadcastScore(priorityOfferedContents);
      final otherContents = await _contentRepository.getRandomSummariesExcluding(
        maxOfferedContents - priorityContents.length,
        {for (final summary in priorityContents) summary.contentId},
        _random,
      );
      final offered = [
        for (final summary in [...priorityContents, ...otherContents]) _offeredContentOf(summary),
      ];
      return Right(_exchangeCodecGateway.encodeOffer(ExchangeOffer(contents: offered)));
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('BuildExchangeOfferUsecase', error, stackTrace);
      return const Left(BuildExchangeOfferFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('BuildExchangeOfferUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'BuildExchangeOfferUsecase', error: error, stackTrace: stackTrace);
      return const Left(BuildExchangeOfferFailure.unknown);
    }
  }

  /// Traduit le résumé [summary] d'un contenu en entrée de l'offre.
  ///
  /// - [summary] : résumé du contenu proposé.
  OfferedContent _offeredContentOf(ContentSummary summary) {
    return OfferedContent(
      id: summary.contentId,
      sizeInBytes: summary.sizeInBytes,
      reactionCount: summary.reactionCount,
      latestReactionAt: summary.latestReactionAt,
    );
  }
}
