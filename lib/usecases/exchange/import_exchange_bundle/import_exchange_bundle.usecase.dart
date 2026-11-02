import 'dart:convert';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.json_zlib.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/resources/content/content/flair.extension.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:bedbug/resources/content/reaction/reaction.config.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.entity.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.repository.dart';
import 'package:bedbug/resources/content/storage/storage.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/exchange/exchange_import_report/exchange_import_report.value_object.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.hive.dart';
import 'package:bedbug/services/content/content_size.service.dart';
import 'package:bedbug/services/content/drawing_validation.service.dart';
import 'package:bedbug/services/reaction/reaction_merge.service.dart';
import 'package:bedbug/usecases/exchange/import_exchange_bundle/import_exchange_bundle.config.dart';
import 'package:bedbug/usecases/exchange/import_exchange_bundle/import_exchange_bundle.failure.dart';
import 'package:bedbug/usecases/exchange/import_exchange_bundle/import_exchange_bundle.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ImportExchangeBundleUsecase].
final importExchangeBundleUsecaseProvider = Provider<ImportExchangeBundleUsecase>((ref) {
  return ImportExchangeBundleUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(seenContentRepositoryProvider),
    ref.read(signatureRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(exchangeCodecGatewayProvider),
    ref.read(contentSizeServiceProvider),
    ref.read(drawingValidationServiceProvider),
    ref.read(reactionMergeServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Importe le lot reçu d'un pair : enregistre ce qui a été demandé, valide, et écarte tout le reste.
///
/// Tout ce qui arrive d'un pair est falsifiable : ce use case est la frontière où rien n'est cru sans être
/// vérifié ou recalculé.
/// - Seul ce qui a été demandé est accepté ([ImportExchangeBundleParams.requestBytes]) : un pair ne peut pas
///   pousser de contenus non sollicités.
/// - Un contenu déjà possédé ou déjà vu n'est jamais remplacé.
/// - Les champs propres à l'appareil sont fixés ici : provenance publique, rebonds plus un (bornés), dates ramenées
///   à la date du jour si elles sont dans le futur, flair normalisé.
/// - L'auteur est déduit de la signature jointe : son identifiant local est une empreinte de ses champs, si bien
///   que deux contenus portant exactement la même signature se retrouvent sous la même page `s/pseudo`. Une
///   signature invalide est ignorée et le contenu s'affiche en anonyme.
/// - Les limites de contenu sont celles d'un contenu local ([DrawingValidationService], [ContentSizeService]), avec
///   un plafond de poids ([maxReceivedContentBytes]) ; celles des réactions viennent de [ReactionMergeService].
/// - Une réaction n'a pas d'auteur transmis : son identifiant en tient lieu, l'auteur réutilisant le même
///   identifiant quand il modifie sa réaction. Une réaction reçue ne remplace jamais celle de l'utilisateur.
///
/// Tous les contenus reçus, même écartés, sont mémorisés comme déjà vus pour ne pas être redemandés.
class ImportExchangeBundleUsecase
    extends Usecase<ImportExchangeBundleParams, ImportExchangeBundleFailure, ExchangeImportReport> {
  /// Crée un [ImportExchangeBundleUsecase].
  ImportExchangeBundleUsecase(
    this._contentRepository,
    this._reactionRepository,
    this._seenContentRepository,
    this._signatureRepository,
    this._storageRepository,
    this._exchangeCodecGateway,
    this._contentSizeService,
    this._drawingValidationService,
    this._reactionMergeService,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final ReactionRepository _reactionRepository;
  final SeenContentRepository _seenContentRepository;
  final SignatureRepository _signatureRepository;
  final StorageRepository _storageRepository;
  final ExchangeCodecGateway _exchangeCodecGateway;
  final ContentSizeService _contentSizeService;
  final DrawingValidationService _drawingValidationService;
  final ReactionMergeService _reactionMergeService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<ImportExchangeBundleFailure, ExchangeImportReport>> call(ImportExchangeBundleParams params) async {
    try {
      final request = _exchangeCodecGateway.decodeRequest(params.requestBytes);
      final bundle = _exchangeCodecGateway.decodeBundle(params.bundleBytes);
      final now = DateTime.now();
      await _seenContentRepository.deleteSeenBefore(now.subtract(seenContentRetention));

      final requestedIds = request.contentIds.toSet();
      final receivedIds = {
        for (final exchanged in bundle.contents)
          if (requestedIds.contains(exchanged.content.id)) exchanged.content.id,
      };
      final ownedIds = await _contentRepository.getExistingIds(receivedIds);
      final seenIds = await _seenContentRepository.getSeenAmong(receivedIds);

      var importedContents = 0;
      var rejectedContents = 0;
      final handledIds = <String>{};
      final signaturesToSave = <String, Signature>{};
      for (final exchanged in bundle.contents) {
        final received = exchanged.content;
        final isAcceptable =
            receivedIds.contains(received.id) && !ownedIds.contains(received.id) && !seenIds.contains(received.id);
        if (!handledIds.add(received.id) || !isAcceptable) {
          rejectedContents++;
          continue;
        }

        final signature = _validSignature(exchanged.signature, now);
        final content = _receivedContent(received, signature?.id ?? anonymousSignatureId, now);
        if (content == null) {
          rejectedContents++;
          continue;
        }
        if (!await _saveReceivedContent(content)) {
          rejectedContents++;
          continue;
        }
        importedContents++;
        if (signature != null) {
          signaturesToSave[signature.id] = signature;
        }
      }

      if (signaturesToSave.isNotEmpty) {
        await _signatureRepository.saveMany(signaturesToSave.values.toList());
      }
      await _seenContentRepository.addMany([
        for (final id in receivedIds) SeenContent(id: id, createdAt: now, updatedAt: now),
      ]);

      final reactionReport = await _importReactions(bundle.reactions, {
        ...requestedIds,
        ...request.reactionContentIds,
      }, now);

      return Right(
        ExchangeImportReport(
          importedContents: importedContents,
          rejectedContents: rejectedContents,
          importedReactions: reactionReport.imported,
          rejectedReactions: reactionReport.rejected,
        ),
      );
    } on DataException catch (error, stackTrace) {
      AppLogger.error('ImportExchangeBundleUsecase', error, stackTrace);
      return const Left(ImportExchangeBundleFailure.invalidBundle);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('ImportExchangeBundleUsecase', error, stackTrace);
      return const Left(ImportExchangeBundleFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('ImportExchangeBundleUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'ImportExchangeBundleUsecase', error: error, stackTrace: stackTrace);
      return const Left(ImportExchangeBundleFailure.unknown);
    }
  }

  /// Retourne [received] avec les champs propres à l'appareil fixés, ou `null` s'il est invalide.
  ///
  /// - [received] : contenu décodé, tel qu'envoyé par le pair.
  /// - [signatureId] : identifiant local de la signature de l'auteur.
  /// - [now] : date de l'import, borne des dates reçues.
  Content? _receivedContent(Content received, String signatureId, DateTime now) {
    final flair = received.flair.toFlair();
    if (flair == null || flair.length > maxFlairLength) {
      return null;
    }
    if (received is MediaContent && (received.media.isEmpty || received.media.length > maxMediaPerContent)) {
      return null;
    }
    final createdAt = received.createdAt.isAfter(now) ? now : received.createdAt;
    final updatedAt = received.updatedAt.isAfter(now) ? now : received.updatedAt;
    return received.copyWithReception(
      signatureId: signatureId,
      bounce: received.bounce.clamp(0, maxReceivedBounce) + 1,
      createdAt: createdAt,
      updatedAt: updatedAt.isBefore(createdAt) ? createdAt : updatedAt,
      flair: flair,
    );
  }

  /// Enregistre [content] et indique s'il l'a été.
  ///
  /// Un contenu refusé, ou qui échoue à l'écriture, n'empêche pas d'importer les suivants. Son poids est recalculé :
  /// celui annoncé par le pair n'est pas fiable.
  ///
  /// - [content] : contenu reçu, avec ses champs propres à l'appareil.
  Future<bool> _saveReceivedContent(Content content) async {
    try {
      if (content is DrawingContent && !_drawingValidationService.isValid(content.drawing)) {
        return false;
      }
      final sizeInBytes = _contentSizeService.sizeInBytes(content);
      if (sizeInBytes > maxReceivedContentBytes) {
        return false;
      }
      final saved = await _contentRepository.addOne(content.copyWithSizeInBytes(sizeInBytes));
      await _storageRepository.adjustCurrentSizeInBytes(saved.sizeInBytes);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('ImportExchangeBundleUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'ImportExchangeBundleUsecase', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Retourne la signature reçue [signature], vérifiée et rattachée à son identifiant local, ou `null` si elle
  /// est absente ou invalide.
  ///
  /// Les mêmes règles que pour la signature de l'utilisateur s'appliquent (pseudo, bedbug sans mot, description
  /// d'une ligne, identifiants de réseaux bien formés). L'intensité du ghost est bornée plutôt que refusée, et une
  /// couleur hors de 32 bits est remplacée par la couleur par défaut.
  ///
  /// - [signature] : signature jointe au contenu, `null` pour un contenu anonyme.
  /// - [now] : date de l'import.
  Signature? _validSignature(Signature? signature, DateTime now) {
    if (signature == null) {
      return null;
    }
    final bio = signature.bio;
    if (!Signature.isValidPseudo(signature.pseudo) ||
        !Signature.isValidAvatarText(signature.avatarText) ||
        (bio != null && !Signature.isValidBio(bio))) {
      return null;
    }
    for (final entry in signature.socialLinks.entries) {
      if (!RegExp(entry.key.handlePattern).hasMatch(entry.value)) {
        return null;
      }
    }
    final colorArgb = signature.colorArgb;
    final normalized = Signature(
      id: '',
      createdAt: now,
      updatedAt: now,
      pseudo: signature.pseudo,
      avatarText: signature.avatarText,
      colorArgb: colorArgb != null && colorArgb >= 0 && colorArgb <= 0xFFFFFFFF ? colorArgb : null,
      ghostSpeed: signature.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
      bio: bio == null || bio.trim().isEmpty ? null : bio,
      bioFont: signature.bioFont,
      socialLinks: signature.socialLinks,
    );
    return Signature(
      id: _fingerprintOf(normalized),
      createdAt: now,
      updatedAt: now,
      pseudo: normalized.pseudo,
      avatarText: normalized.avatarText,
      colorArgb: normalized.colorArgb,
      ghostSpeed: normalized.ghostSpeed,
      bio: normalized.bio,
      bioFont: normalized.bioFont,
      socialLinks: normalized.socialLinks,
    );
  }

  /// Retourne l'identifiant local de [signature] : une empreinte de tous ses champs visibles.
  ///
  /// Deux signatures identiques au caractère près donnent le même identifiant, et leurs contenus se regroupent ;
  /// la moindre différence (une autre couleur, une autre description) donne une autre signature. L'empreinte
  /// (FNV-1a 64 bits) n'a pas de rôle de sécurité : copier une signature suffit déjà à s'en servir.
  ///
  /// - [signature] : signature reçue, déjà normalisée.
  String _fingerprintOf(Signature signature) {
    final socialLinks = signature.socialLinks.entries.map((entry) => '${entry.key.value}=${entry.value}').toList()
      ..sort();
    final canonical = [
      signature.pseudo,
      signature.avatarText,
      '${signature.colorArgb}',
      '${signature.ghostSpeed}',
      signature.bio ?? '',
      '${signature.bioFont.value}',
      ...socialLinks,
    ].join('\u0000');

    // Base de décalage FNV-1a 64 bits (0xcbf29ce484222325), écrite en décimal signé : les entiers Dart font
    // 64 bits signés, et la multiplication déborde en boucle, comme l'exige FNV.
    var hash = -3750763034362895579;
    for (final byte in utf8.encode(canonical)) {
      hash = (hash ^ byte) * 0x100000001b3;
    }
    final high = ((hash >> 32) & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    final low = (hash & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return '$peerSignatureIdPrefix$high$low';
  }

  /// Importe les réactions reçues sur les contenus de [allowedContentIds], et retourne le nombre de réactions
  /// importées et écartées.
  ///
  /// - [reactions] : réactions décodées, sans auteur.
  /// - [allowedContentIds] : contenus dont les réactions ont été demandées.
  /// - [now] : date de l'import, borne des dates reçues.
  Future<({int imported, int rejected})> _importReactions(
    List<Reaction> reactions,
    Set<String> allowedContentIds,
    DateTime now,
  ) async {
    final existingContentIds = await _contentRepository.getExistingIds(allowedContentIds);
    final localReactionIdsByContent = <String, Set<String>>{};
    final receivedCountByContent = <String, int>{};
    final handledIds = <String>{};
    var imported = 0;
    var rejected = 0;

    for (final received in reactions) {
      final contentId = received.contentId;
      if (!existingContentIds.contains(contentId) || !handledIds.add(received.id)) {
        rejected++;
        continue;
      }
      final receivedCount = (receivedCountByContent[contentId] ?? 0) + 1;
      receivedCountByContent[contentId] = receivedCount;
      if (receivedCount > maxReactionsPerContent) {
        rejected++;
        continue;
      }

      final localReactionIds = localReactionIdsByContent[contentId] ??= await _localReactionIdsOf(contentId);
      if (localReactionIds.contains(received.id)) {
        rejected++;
        continue;
      }

      final createdAt = received.createdAt.isAfter(now) ? now : received.createdAt;
      final updatedAt = received.updatedAt.isAfter(now) ? now : received.updatedAt;
      final isSaved = await _saveReceivedReaction(
        Reaction(
          id: received.id,
          createdAt: createdAt,
          updatedAt: updatedAt.isBefore(createdAt) ? createdAt : updatedAt,
          contentId: contentId,
          authorId: received.id,
          avatarText: received.avatarText,
          bubbleText: received.bubbleText,
          colorArgb: received.colorArgb,
          ghostSpeed: received.ghostSpeed,
          bubbleFont: received.bubbleFont,
        ),
      );
      if (!isSaved) {
        rejected++;
        continue;
      }
      imported++;
    }
    return (imported: imported, rejected: rejected);
  }

  /// Enregistre [reaction] selon les règles de [ReactionMergeService], et indique si elle a été traitée.
  ///
  /// Une version plus ancienne que celle connue compte comme traitée : elle n'est simplement pas écrite. Une réaction
  /// refusée, ou qui échoue à l'écriture, n'empêche pas d'importer les suivantes.
  ///
  /// - [reaction] : réaction reçue, avec ses champs propres à l'appareil.
  Future<bool> _saveReceivedReaction(Reaction reaction) async {
    try {
      final normalized = _reactionMergeService.normalize(reaction);
      if (normalized == null) {
        return false;
      }
      final existingReactions = await _reactionRepository.getAllByContentId(normalized.contentId);
      final merge = _reactionMergeService.merge(existingReactions, normalized);
      if (!merge.isNewReactionKept) {
        return true;
      }

      await _reactionRepository.deleteMany(merge.replacedIds);
      await _reactionRepository.addOne(normalized);
      if (merge.overflowIds.isNotEmpty) {
        await _reactionRepository.deleteMany(merge.overflowIds);
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('ImportExchangeBundleUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'ImportExchangeBundleUsecase', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Retourne les identifiants des réactions de l'utilisateur sur le contenu [contentId].
  ///
  /// Une réaction de l'utilisateur, relayée par un pair puis revenue, ne doit pas être réimportée : elle
  /// remplacerait l'originale sous un autre auteur, et l'utilisateur ne la retrouverait plus comme la sienne.
  ///
  /// - [contentId] : contenu dont on cherche les réactions de l'utilisateur.
  Future<Set<String>> _localReactionIdsOf(String contentId) async {
    final reactions = await _reactionRepository.getAllByContentId(contentId);
    return {
      for (final reaction in reactions)
        if (reaction.authorId == localSignatureId) reaction.id,
    };
  }
}
