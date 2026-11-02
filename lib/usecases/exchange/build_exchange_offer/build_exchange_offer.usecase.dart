import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.json_zlib.dart';
import 'package:bedbug/gateways/exchange/exchange_offer/exchange_offer.value_object.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.hive.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/exchange/build_exchange_offer/build_exchange_offer.config.dart';
import 'package:bedbug/usecases/exchange/build_exchange_offer/build_exchange_offer.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [BuildExchangeOfferUsecase].
final buildExchangeOfferUsecaseProvider = Provider<BuildExchangeOfferUsecase>((ref) {
  return BuildExchangeOfferUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(reactionRepositoryProvider),
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
    this._reactionRepository,
    this._exchangeCodecGateway,
    this._random,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final ReactionRepository _reactionRepository;
  final ExchangeCodecGateway _exchangeCodecGateway;
  final Random _random;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<BuildExchangeOfferFailure, Uint8List>> call(NoParams params) async {
    try {
      final priorityContents = await _contentRepository.getTopByBroadcastScore(priorityOfferedContents);
      final otherContents = await _contentRepository.getRandomExcluding(
        maxOfferedContents - priorityContents.length,
        priorityContents.map((content) => content.id).toSet(),
        _random,
      );
      final offered = <OfferedContent>[];
      for (final content in [...priorityContents, ...otherContents]) {
        final reactions = await _reactionRepository.getAllByContentId(content.id);
        DateTime? latestReactionAt;
        for (final reaction in reactions) {
          if (latestReactionAt == null || reaction.updatedAt.isAfter(latestReactionAt)) {
            latestReactionAt = reaction.updatedAt;
          }
        }
        offered.add(
          OfferedContent(
            id: content.id,
            sizeInBytes: content.sizeInBytes,
            reactionCount: reactions.length,
            latestReactionAt: latestReactionAt,
          ),
        );
      }
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
}
