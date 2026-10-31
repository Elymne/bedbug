import 'dart:typed_data';

import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_codec_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_offer.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/json_zlib_exchange_codec_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [BuildExchangeOfferUsecase].
final buildExchangeOfferUsecaseProvider = Provider<BuildExchangeOfferUsecase>((ref) {
  return BuildExchangeOfferUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(exchangeCodecGatewayProvider),
  );
});

/// Nombre maximal de contenus proposés dans une offre.
///
/// Une offre ne transporte que des identifiants (environ 60 octets par contenu une fois compressée) : 50 contenus
/// tiennent en quelques kilo-octets, une fraction de seconde en BLE, tout en laissant au pair un vrai choix.
const int maxOfferedContents = 50;

/// Construit l'offre envoyée à un pair au début d'un échange, déjà encodée pour le transport.
///
/// Un échange commence par proposer, pas par envoyer : on ne connaît pas encore ce que le pair possède, et
/// pousser des contenus à l'aveugle gaspillerait une bande passante BLE rare (quelques dizaines de Ko/s). L'offre
/// liste donc les [maxOfferedContents] contenus de plus fort `broadcastScore` (les plus « chauds », et toujours
/// ceux de l'utilisateur), du plus prioritaire au moins prioritaire. Pour chacun, elle résume ses réactions
/// (nombre, date de la plus récente) : un pair qui possède déjà le contenu peut ainsi ne demander que les
/// réactions qui lui manquent.
class BuildExchangeOfferUsecase extends Usecase<NoParams, BuildExchangeOfferFailure, Uint8List> {
  /// Crée un [BuildExchangeOfferUsecase].
  BuildExchangeOfferUsecase(this._contentRepository, this._reactionRepository, this._exchangeCodecGateway);

  final ContentRepository _contentRepository;
  final ReactionRepository _reactionRepository;
  final ExchangeCodecGateway _exchangeCodecGateway;

  @override
  Future<Either<BuildExchangeOfferFailure, Uint8List>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getTopByBroadcastScore(maxOfferedContents);
      final offered = <OfferedContent>[];
      for (final content in contents) {
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
      return const Left(BuildExchangeOfferFailure.unknown);
    }
  }
}

/// Échecs possibles du [BuildExchangeOfferUsecase].
enum BuildExchangeOfferFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la construction de l'offre.
  unknown,
}
