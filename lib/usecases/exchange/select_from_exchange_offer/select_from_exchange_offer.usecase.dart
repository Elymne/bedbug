import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.config.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.json_zlib.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/exchange/select_from_exchange_offer/select_from_exchange_offer.config.dart';
import 'package:bedbug/usecases/exchange/select_from_exchange_offer/select_from_exchange_offer.failure.dart';
import 'package:bedbug/usecases/exchange/select_from_exchange_offer/select_from_exchange_offer.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SelectFromExchangeOfferUsecase].
final selectFromExchangeOfferUsecaseProvider = Provider<SelectFromExchangeOfferUsecase>((ref) {
  return SelectFromExchangeOfferUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(seenContentRepositoryProvider),
    ref.read(exchangeCodecGatewayProvider),
    Random(),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Choisit, dans l'offre d'un pair, ce que l'appareil veut recevoir, et retourne la demande encodée.
///
/// C'est celui qui reçoit qui choisit, et au hasard : un pair ne peut pas imposer ce qui circule, et deux
/// appareils qui reçoivent la même offre ne repartent pas avec les mêmes contenus, ce qui diversifie la
/// diffusion. Le tirage est pondéré par la place dans l'offre (rangée par priorité de diffusion décroissante),
/// avec un plancher ([selectionWeightFloor]) : les contenus récents passent plus souvent, les autres passent
/// quand même.
///
/// Sont écartés d'office les contenus déjà possédés et ceux déjà vus puis supprimés (voir
/// [SeenContentRepository]). Le tirage s'arrête au budget de l'échange (nombre de contenus et poids cumulé) ;
/// un contenu trop lourd pour ce qui reste est sauté au profit des suivants, ce qui laisse passer les petits.
///
/// Pour les contenus déjà possédés, seules les réactions sont redemandées, si le pair en a de plus récentes.
class SelectFromExchangeOfferUsecase
    extends Usecase<SelectFromExchangeOfferParams, SelectFromExchangeOfferFailure, Uint8List> {
  /// Crée un [SelectFromExchangeOfferUsecase].
  SelectFromExchangeOfferUsecase(
    this._contentRepository,
    this._reactionRepository,
    this._seenContentRepository,
    this._exchangeCodecGateway,
    this._random,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final ReactionRepository _reactionRepository;
  final SeenContentRepository _seenContentRepository;
  final ExchangeCodecGateway _exchangeCodecGateway;
  final Random _random;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SelectFromExchangeOfferFailure, Uint8List>> call(SelectFromExchangeOfferParams params) async {
    try {
      final offer = _exchangeCodecGateway.decodeOffer(params.offerBytes);
      // Une offre plus longue que ce qu'un pair honnête envoie est tronquée ; les doublons et les poids
      // négatifs sont ignorés.
      final offered = <OfferedContent>[];
      final offeredIds = <String>{};
      for (final content in offer.contents.take(maxOfferedContents)) {
        if (content.sizeInBytes >= 0 && offeredIds.add(content.id)) {
          offered.add(content);
        }
      }

      final ownedIds = await _contentRepository.getExistingIds(offeredIds);
      final seenIds = await _seenContentRepository.getSeenAmong(offeredIds);

      final candidates = <_Candidate>[];
      for (var rank = 0; rank < offered.length; rank++) {
        final content = offered[rank];
        if (!ownedIds.contains(content.id) && !seenIds.contains(content.id)) {
          candidates.add(_Candidate(content, _weightOf(rank, offered.length)));
        }
      }

      final request = ExchangeRequest(
        contentIds: _drawWithinBudget(candidates, params.maxContents, params.maxBytes),
        reactionContentIds: await _contentsWithNewerReactions(offered.where((item) => ownedIds.contains(item.id))),
      );
      return Right(_exchangeCodecGateway.encodeRequest(request));
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SelectFromExchangeOfferUsecase', error, stackTrace);
      return const Left(SelectFromExchangeOfferFailure.invalidOffer);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SelectFromExchangeOfferUsecase', error, stackTrace);
      return const Left(SelectFromExchangeOfferFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SelectFromExchangeOfferUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SelectFromExchangeOfferUsecase', error: error, stackTrace: stackTrace);
      return const Left(SelectFromExchangeOfferFailure.unknown);
    }
  }

  /// Retourne le poids dans le tirage du contenu placé en [rank] sur [count] : de `1` pour le premier à
  /// [selectionWeightFloor] pour le dernier, en décroissant linéairement.
  ///
  /// - [rank] : place du contenu dans l'offre, à partir de `0`.
  /// - [count] : nombre de contenus dans l'offre.
  double _weightOf(int rank, int count) {
    if (count <= 1) {
      return 1;
    }
    return 1 - (1 - selectionWeightFloor) * rank / (count - 1);
  }

  /// Tire au hasard, sans remise, les contenus à demander parmi [candidates], dans la limite du budget.
  ///
  /// Tirage pondéré d'Efraimidis et Spirakis : chaque candidat reçoit la clé `u^(1/poids)`, `u` uniforme dans
  /// `]0, 1]`, et l'ordre des clés décroissantes est un tirage sans remise proportionnel aux poids. Les candidats
  /// sont ensuite pris dans cet ordre tant que le budget le permet ; un candidat trop lourd pour ce qui reste est
  /// sauté.
  ///
  /// - [candidates] : contenus demandables, avec leur poids.
  /// - [maxContents] : nombre maximal de contenus à demander.
  /// - [maxBytes] : poids cumulé maximal, en octets.
  List<String> _drawWithinBudget(List<_Candidate> candidates, int maxContents, int maxBytes) {
    final keyed = [
      for (final candidate in candidates)
        (candidate: candidate, key: pow(1 - _random.nextDouble(), 1 / candidate.weight)),
    ]..sort((first, second) => second.key.compareTo(first.key));

    final selected = <String>[];
    var remainingBytes = maxBytes;
    for (final entry in keyed) {
      if (selected.length >= maxContents) {
        break;
      }
      final size = entry.candidate.content.sizeInBytes;
      if (size > remainingBytes) {
        continue;
      }
      selected.add(entry.candidate.content.id);
      remainingBytes -= size;
    }
    return selected;
  }

  /// Retourne, parmi les contenus [owned] déjà possédés, ceux dont le pair annonce des réactions plus récentes
  /// ou plus nombreuses, dans la limite de [maxReactionRefreshContents].
  ///
  /// - [owned] : contenus de l'offre déjà présents sur l'appareil, dans l'ordre de l'offre.
  Future<List<String>> _contentsWithNewerReactions(Iterable<OfferedContent> owned) async {
    final refresh = <String>[];
    for (final offered in owned) {
      if (refresh.length >= maxReactionRefreshContents) {
        break;
      }
      final offeredLatest = offered.latestReactionAt;
      if (offeredLatest == null) {
        continue;
      }
      final reactions = await _reactionRepository.getAllByContentId(offered.id);
      final isNewer = reactions.every((reaction) => reaction.updatedAt.isBefore(offeredLatest));
      if (isNewer || offered.reactionCount > reactions.length) {
        refresh.add(offered.id);
      }
    }
    return refresh;
  }
}

/// Un contenu demandable et son poids dans le tirage.
class _Candidate {
  /// Crée un [_Candidate].
  ///
  /// - [content] : contenu proposé.
  /// - [weight] : poids dans le tirage, strictement positif.
  const _Candidate(this.content, this.weight);

  /// Contenu proposé.
  final OfferedContent content;

  /// Poids dans le tirage, strictement positif.
  final double weight;
}
