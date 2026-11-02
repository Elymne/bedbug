import 'dart:typed_data';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.config.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.json_zlib.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.hive.dart';
import 'package:bedbug/usecases/exchange/build_exchange_bundle/build_exchange_bundle.failure.dart';
import 'package:bedbug/usecases/exchange/build_exchange_bundle/build_exchange_bundle.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [BuildExchangeBundleUsecase].
final buildExchangeBundleUsecaseProvider = Provider<BuildExchangeBundleUsecase>((ref) {
  return BuildExchangeBundleUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(signatureRepositoryProvider),
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
/// emporte donc la signature complète de son auteur, que le pair rattache lui-même à un identifiant local. Un contenu
/// anonyme, ou dont la signature n'est plus connue, part sans signature et s'affiche en anonyme. Les réactions
/// partent sans auteur : elles ne l'affichent pas.
///
/// Une demande plus longue que ce qu'un pair honnête envoie est tronquée.
class BuildExchangeBundleUsecase extends Usecase<BuildExchangeBundleParams, BuildExchangeBundleFailure, Uint8List> {
  /// Crée un [BuildExchangeBundleUsecase].
  BuildExchangeBundleUsecase(
    this._contentRepository,
    this._reactionRepository,
    this._signatureRepository,
    this._exchangeCodecGateway,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final ReactionRepository _reactionRepository;
  final SignatureRepository _signatureRepository;
  final ExchangeCodecGateway _exchangeCodecGateway;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<BuildExchangeBundleFailure, Uint8List>> call(BuildExchangeBundleParams params) async {
    try {
      final request = _exchangeCodecGateway.decodeRequest(params.requestBytes);
      final contentIds = request.contentIds.toSet().take(defaultMaxRequestedContents).toList();
      final reactionContentIds = request.reactionContentIds.toSet().take(maxReactionRefreshContents).toList();

      final contents = await _contentRepository.getByIds(contentIds);
      final signaturesById = <String, Signature?>{};
      final exchanged = <ExchangedContent>[];
      for (final content in contents) {
        if (!signaturesById.containsKey(content.signatureId)) {
          signaturesById[content.signatureId] = await _signatureOf(content);
        }
        exchanged.add(ExchangedContent(content: content, signature: signaturesById[content.signatureId]));
      }

      final reactions = <Reaction>[];
      final existingReactionContentIds = await _contentRepository.getExistingIds(reactionContentIds.toSet());
      for (final contentId in {...contents.map((content) => content.id), ...existingReactionContentIds}) {
        reactions.addAll(await _reactionRepository.getAllByContentId(contentId));
      }

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

  /// Retourne la signature à joindre à [content], ou `null` s'il doit partir anonyme.
  ///
  /// - [content] : contenu envoyé.
  Future<Signature?> _signatureOf(Content content) async {
    if (content.signatureId == anonymousSignatureId) {
      return null;
    }
    if (content.signatureId == localSignatureId) {
      return _signatureRepository.getLocal();
    }
    return _signatureRepository.getById(content.signatureId);
  }
}
