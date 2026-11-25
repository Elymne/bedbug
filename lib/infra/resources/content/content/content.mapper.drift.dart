import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.extension.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/content_type.enum.dart';
import 'package:bedbug/infra/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/link_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/media_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/tag.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.codec.binary.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:drift/drift.dart';

/// Conversion entre un [Content] et sa ligne de la table `contents`.
///
/// Séparée du repository parce que plusieurs lectures (contenu seul, contenu détaillé avec son auteur) reconstruisent
/// des contenus depuis la même ligne : la conversion n'est écrite qu'une fois. Une seule table couvre tous les
/// sous-types, distingués par la colonne `type` ; les colonnes propres à un sous-type restent nulles pour les autres.
abstract final class ContentDriftMapper {
  /// Reconstruit le contenu concret d'une ligne, selon son type.
  ///
  /// Une ligne incohérente (type inconnu, champ obligatoire absent, dessin illisible) lève une [DataException] :
  /// elle ne peut venir que d'une écriture corrompue, et ne doit pas faire planter toute la liste qui la lit.
  ///
  /// [row] : ligne lue dans la table `contents`.
  static Content toEntity(ContentRow row) {
    try {
      return _toEntity(row);
    } on DataException {
      rethrow;
    } catch (error) {
      throw DataException('ContentDriftMapper', error);
    }
  }

  /// Construit la ligne à écrire pour un contenu.
  ///
  /// Le titre est aussi écrit en minuscules (`search_title`), pour que la recherche le compare à la saisie en SQL avec
  /// la même règle de casse que Dart.
  ///
  /// [entity] : contenu à écrire.
  /// [storedAt] : date d'enregistrement sur ce téléphone, à fournir à l'insertion ; absente, la colonne n'est pas
  /// écrite, ce qui la conserve lors d'une mise à jour.
  static ContentsCompanion toCompanion(Content entity, {DateTime? storedAt}) {
    final companion = ContentsCompanion(
      id: Value(entity.id),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      storedAt: Value.absentIfNull(storedAt),
      signatureId: Value(entity.signatureId),
      origin: Value(entity.origin.value),
      bounce: Value(entity.bounce),
      title: Value(entity.title),
      searchTitle: Value(entity.title.toLowerCase()),
      flair: Value(entity.flair),
      sizeInBytes: Value(entity.sizeInBytes),
      broadcastScore: Value(entity.broadcastScore),
      survivalScore: Value(entity.survivalScore),
      displayScore: Value(entity.displayScore),
      tagValues: Value([for (final tag in entity.tags) tag.value]),
    );
    if (entity is TextContent) {
      return companion.copyWith(
        type: Value(ContentType.text.value),
        body: Value(entity.body),
        mediaUrls: const Value([]),
        mediaKinds: const Value([]),
      );
    }
    if (entity is LinkContent) {
      return companion.copyWith(
        type: Value(ContentType.link.value),
        body: Value(entity.body),
        url: Value(entity.url),
        ogImageUrl: Value(entity.ogImageUrl),
        ogTitle: Value(entity.ogTitle),
        ogDescription: Value(entity.ogDescription),
        mediaUrls: const Value([]),
        mediaKinds: const Value([]),
      );
    }
    if (entity is MediaContent) {
      return companion.copyWith(
        type: Value(ContentType.media.value),
        body: Value(entity.body),
        mediaUrls: Value([for (final media in entity.media) media.url]),
        mediaKinds: Value([for (final media in entity.media) media.kind.value]),
      );
    }
    if (entity is DrawingContent) {
      return companion.copyWith(
        type: Value(ContentType.drawing.value),
        drawingData: Value(const DrawingBinaryCodec().encode(entity.drawing)),
        mediaUrls: const Value([]),
        mediaKinds: const Value([]),
      );
    }
    throw UnimplementedError('ContentDriftMapper.toCompanion : type ${entity.runtimeType} non supporté.');
  }

  /// Reconstruit le contenu d'une ligne, sans traduire ses erreurs.
  ///
  /// [row] : ligne lue dans la table `contents`.
  static Content _toEntity(ContentRow row) {
    final tags = [for (final value in row.tagValues) Tag.values.firstWhere((tag) => tag.value == value)];
    final origin = ContentOrigin.values.firstWhere((candidate) => candidate.value == row.origin);
    if (row.type == ContentType.text.value) {
      return TextContent(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        signatureId: row.signatureId,
        origin: origin,
        broadcastScore: row.broadcastScore,
        survivalScore: row.survivalScore,
        displayScore: row.displayScore,
        bounce: row.bounce,
        title: row.title!,
        body: row.body!,
        flair: row.flair,
        sizeInBytes: row.sizeInBytes,
        tags: tags,
      );
    }
    if (row.type == ContentType.link.value) {
      return LinkContent(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        signatureId: row.signatureId,
        origin: origin,
        broadcastScore: row.broadcastScore,
        survivalScore: row.survivalScore,
        displayScore: row.displayScore,
        bounce: row.bounce,
        title: row.title ?? row.url!,
        body: row.body,
        url: row.url!,
        flair: row.flair,
        sizeInBytes: row.sizeInBytes,
        ogImageUrl: row.ogImageUrl,
        ogTitle: row.ogTitle,
        ogDescription: row.ogDescription,
        tags: tags,
      );
    }
    if (row.type == ContentType.media.value) {
      return MediaContent(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        signatureId: row.signatureId,
        origin: origin,
        broadcastScore: row.broadcastScore,
        survivalScore: row.survivalScore,
        displayScore: row.displayScore,
        bounce: row.bounce,
        media: [
          for (var index = 0; index < row.mediaUrls.length; index++)
            ContentMedia(
              url: row.mediaUrls[index],
              kind: index < row.mediaKinds.length ? MediaKind.fromValue(row.mediaKinds[index]) : MediaKind.image,
            ),
        ],
        title: row.title!,
        body: row.body,
        flair: row.flair,
        sizeInBytes: row.sizeInBytes,
        tags: tags,
      );
    }
    if (row.type == ContentType.drawing.value) {
      return DrawingContent(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        signatureId: row.signatureId,
        origin: origin,
        broadcastScore: row.broadcastScore,
        survivalScore: row.survivalScore,
        displayScore: row.displayScore,
        bounce: row.bounce,
        drawing: const DrawingBinaryCodec().decode(row.drawingData!),
        title: row.title!,
        flair: row.flair,
        sizeInBytes: row.sizeInBytes,
        tags: tags,
      );
    }
    throw DataException('ContentDriftMapper', 'type "${row.type}" non supporté');
  }
}
