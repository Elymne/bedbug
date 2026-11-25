import 'dart:typed_data';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/gateways/exchange/exchange_codec/exchange_codec.config.dart';
import 'package:bedbug/infra/gateways/exchange/exchange_codec/exchange_codec.gateway.dart';
import 'package:bedbug/infra/gateways/exchange/exchange_codec/exchange_codec.gateway.json_zlib.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/exchange/build_exchange_bundle/build_exchange_bundle.failure.dart';
import 'package:bedbug/logic/usecases/exchange/build_exchange_bundle/build_exchange_bundle.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [BuildExchangeBundleUsecase].
final buildExchangeBundleUsecaseProvider = Provider<BuildExchangeBundleUsecase>((ref) {
  return BuildExchangeBundleUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(exchangeCodecGatewayProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Construit le lot demandé par un pair, déjà encodé pour le transport.
///
/// Répond à la demande produite par le pair (`SelectFromExchangeOfferUsecase`) : les contenus demandés, toutes
/// leurs réactions, et les réactions des contenus dont seules les réactions étaient demandées.
///
/// Aucun identifiant de signature ne sort du téléphone : sans serveur, un identifiant ne prouve rien, et le
/// `signatureId` `local` des contenus de l'utilisateur prendrait chez le pair la signature de ce pair. Chaque contenu
/// emporte donc la signature complète de son auteur, lue avec lui, que le pair rattache lui-même à un identifiant
/// local. Un contenu anonyme, ou dont la signature n'est plus connue, part sans signature et s'affiche en anonyme.
/// Les réactions partent sans auteur : elles ne l'affichent pas.
///
/// Une demande plus longue que ce qu'un pair honnête envoie est tronquée.
class BuildExchangeBundleUsecase extends Usecase<BuildExchangeBundleParams, BuildExchangeBundleFailure, Uint8List> {
  /// Crée un [BuildExchangeBundleUsecase].
  BuildExchangeBundleUsecase(
    this._contentRepository,
    this._reactionRepository,
    this._exchangeCodecGateway,
    this._errorLogRepository,
  );

  /// Repository des contenus, qui les lit avec la signature de leur auteur.
  final ContentRepository _contentRepository;

  /// Repository des réactions envoyées avec les contenus.
  final ReactionRepository _reactionRepository;

  /// Codec des messages d'échange.
  final ExchangeCodecGateway _exchangeCodecGateway;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<BuildExchangeBundleFailure, Uint8List>> call(BuildExchangeBundleParams params) async {
    try {
      final request = _exchangeCodecGateway.decodeRequest(params.requestBytes);
      final contentIds = request.contentIds.toSet().take(defaultMaxRequestedContents).toList();
      final reactionContentIds = request.reactionContentIds.toSet().take(maxReactionRefreshContents).toSet();

      final contents = await _contentRepository.getDetailedByIds(contentIds);
      final exchanged = [
        for (final detailed in contents) ExchangedContent(content: detailed.content, signature: detailed.signature),
      ];

      // Les réactions de contenus absents n'existent pas : inutile de vérifier lesquels sont encore là.
      final reactions = await _reactionRepository.getAllByContentIds({
        for (final detailed in contents) detailed.content.id,
        ...reactionContentIds,
      });

      final bundle = ExchangeBundle(contents: exchanged, reactions: reactions);
      return Right(_exchangeCodecGateway.encodeBundle(bundle));
    } on DataException catch (error, stackTrace) {
      AppLogger.error('BuildExchangeBundleUsecase', error, stackTrace);
      return const Left(BuildExchangeBundleFailure.invalidRequest);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('BuildExchangeBundleUsecase', error, stackTrace);
      return const Left(BuildExchangeBundleFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('BuildExchangeBundleUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'BuildExchangeBundleUsecase', error: error, stackTrace: stackTrace);
      return const Left(BuildExchangeBundleFailure.unknown);
    }
  }
}
