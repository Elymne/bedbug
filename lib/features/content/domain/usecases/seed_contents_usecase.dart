import 'dart:math';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/object_values/content_image.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SeedContentsUsecase].
final seedContentsUsecaseProvider = Provider<SeedContentsUsecase>((ref) {
  return SeedContentsUsecase(ref.read(contentRepositoryProvider), ref.read(storageRepositoryProvider));
});

/// URLs de liens valides utilisées comme exemples réalistes.
const List<String> _validUrls = [
  'https://flutter.dev',
  'https://dart.dev',
  'https://pub.dev',
  'https://github.com',
  'https://stackoverflow.com',
];

/// URLs intentionnellement cassées pour tester les états d'erreur.
const List<String> _brokenUrls = [
  'https://this-domain-does-not-exist-xyz-bedbug.com',
  'https://example.com/page-that-does-not-exist-404',
  'not-a-url-at-all',
  'https://broken-og-image-test.invalid/article',
];

/// Noms de fichiers image valides (fichiers inexistants — tests d'affichage).
const List<String> _validImageFileNames = [
  'photo_landscape.jpg',
  'avatar_user.png',
  'thumbnail_preview.webp',
  'cover_article.jpeg',
];

/// Noms de fichiers image intentionnellement cassés pour tester les états d'erreur.
const List<String> _brokenImageFileNames = ['nonexistent_file.jpg', 'missing_image.png', 'corrupt.xyz', ''];

/// Dimensions natives (largeur, hauteur) des images de seed.
///
/// Couvre les trois zones de la hauteur d'affichage :
/// - sous le minimum (300px) → clampé à 300
/// - dans la plage (300–600px) → affiché tel quel
/// - au-dessus du maximum (600px) → clampé à 600
const List<(int, int)> _imageDimensions = [
  (1080, 200), // hauteur sous le min → clampé à 300
  (1080, 400), // hauteur dans la plage
  (1080, 600), // hauteur exactement au max
  (1080, 900), // hauteur au-dessus du max → clampé à 600
  (400, 350), // image presque carrée, dans la plage
  (1920, 1080), // paysage HD → clampé à 600
];

/// Provenances attribuées à tour de rôle aux contenus générés.
///
/// [ContentOrigin.owned] est volontairement exclu : les contenus factices
/// sont signés par des utilisateurs factices, ils ne doivent jamais passer
/// pour des contenus de l'utilisateur (liste « Mes posts », suppression).
const List<ContentOrigin> _seedOrigins = [ContentOrigin.public, ContentOrigin.subscribed, ContentOrigin.favorited];

/// Flairs d'exemple, attribués à tour de rôle aux contenus générés.
const List<String> _flairs = ['france', 'paris', 'musique', 'tech', 'random'];

/// Titres courts pour [TextContent] et [LinkContent].
const List<String> _shortTitles = ['Note rapide', 'Idée', 'À lire', 'Info', 'Rappel'];

/// Titres longs pour couvrir le débordement dans les tiles.
const List<String> _longTitles = [
  'Ceci est un titre très long destiné à tester le comportement du widget tile lorsque le texte dépasse la largeur disponible',
  'Un autre titre volontairement excessif pour valider la gestion des overflow et le nombre de lignes maximum affiché dans la liste',
];

/// Corps courts pour [TextContent].
const List<String> _shortBodies = ['Corps court.', 'Un peu de texte.', 'Rien de spécial.'];

/// Corps longs pour [TextContent].
const List<String> _longBodies = [
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
      'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
  'Voici un corps de contenu volontairement très long pour s\'assurer que la mise en page du tile gère correctement les textes '
      'multi-paragraphes et que le rendu reste cohérent quelle que soit la quantité de texte affichée.',
];

/// Génère une grande quantité de contenus factices pour les tests de charge et d'affichage.
class SeedContentsUsecase extends Usecase<SeedContentsParams, SeedContentsFailure, void> {
  /// Crée un [SeedContentsUsecase].
  SeedContentsUsecase(this._contentRepository, this._storageRepository);

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;

  /// Nombre d'items écrits en une seule opération Hive.
  static const int _batchSize = 500;

  @override
  Future<Either<SeedContentsFailure, void>> call(SeedContentsParams params) async {
    try {
      final now = DateTime.now();
      final random = Random(params.randomSeed);
      final batch = <Content>[];
      var totalSizeInBytes = 0;

      for (var index = 0; index < params.count; index++) {
        final createdAt = now.subtract(Duration(minutes: index));
        final origin = _seedOrigins[index % _seedOrigins.length];
        final bounce = index % 11;
        final flair = _flairs[index % _flairs.length];

        final authorId = _pickAuthorId(params, random, index);
        final content = _buildContent(index, createdAt, origin, bounce, flair, authorId);
        totalSizeInBytes += content.sizeInBytes;
        batch.add(content);

        if (batch.length == _batchSize) {
          await _contentRepository.addMany(List.from(batch));
          batch.clear();
        }
      }

      if (batch.isNotEmpty) {
        await _contentRepository.addMany(List.from(batch));
      }

      if (totalSizeInBytes > 0) {
        await _storageRepository.adjustCurrentSizeInBytes(totalSizeInBytes);
      }

      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SeedContentsUsecase', error, stackTrace);
      return const Left(SeedContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SeedContentsUsecase', error, stackTrace);
      return const Left(SeedContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SeedContentsUsecase', error, stackTrace);
      return const Left(SeedContentsFailure.unknown);
    }
  }

  /// Choisit l'auteur du contenu factice d'index [index].
  ///
  /// Tiré au hasard parmi [SeedContentsParams.authorIds] pour que chaque
  /// auteur factice signe un échantillon varié de contenus (et que la
  /// recherche par utilisateur ait de quoi être testée). Sans auteur fourni,
  /// retombe sur cinq identifiants fictifs sans profil.
  ///
  /// - [params] : paramètres du seed, portant les auteurs disponibles.
  /// - [random] : générateur partagé par tout le seed.
  /// - [index] : position du contenu dans le seed.
  String _pickAuthorId(SeedContentsParams params, Random random, int index) {
    if (params.authorIds.isEmpty) {
      return 'seed-author-${index % 5}';
    }
    return params.authorIds[random.nextInt(params.authorIds.length)];
  }

  /// Construit un contenu factice selon le modulo de [index] pour distribuer les types.
  ///
  /// - index % 10 in [0..3] → [TextContent] (40 %)
  /// - index % 10 in [4..6] → [ImageContent] (30 %)
  /// - index % 10 in [7..9] → [LinkContent] (30 %)
  Content _buildContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
  ) {
    final bucket = index % 10;

    if (bucket <= 3) {
      return _buildTextContent(index, createdAt, origin, bounce, flair, authorId);
    }

    if (bucket <= 6) {
      return _buildImageContent(index, createdAt, origin, bounce, flair, authorId);
    }

    return _buildLinkContent(index, createdAt, origin, bounce, flair, authorId);
  }

  /// Construit un [TextContent] avec titre court, long, ou corps vide selon l'index.
  TextContent _buildTextContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
  ) {
    final isLongTitle = index % 7 == 0;
    final isLongBody = index % 5 == 0;

    final title = isLongTitle
        ? _longTitles[index % _longTitles.length]
        : '${_shortTitles[index % _shortTitles.length]} #${index + 1}';

    final body = isLongBody ? _longBodies[index % _longBodies.length] : _shortBodies[index % _shortBodies.length];

    return TextContent(
      id: UuidX.generate(),
      createdAt: createdAt,
      updatedAt: createdAt,
      authorId: authorId,
      senderId: 'seed-sender',
      origin: origin,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: bounce,
      sizeInBytes: body.length,
      flair: flair,
      title: title,
      body: body,
    );
  }

  /// Construit un [ImageContent] avec des noms de fichiers valides ou cassés selon l'index.
  ImageContent _buildImageContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
  ) {
    final isBroken = index % 4 == 0;
    final fileNames = isBroken ? _brokenImageFileNames : _validImageFileNames;
    // 1 à 4 images selon l'index, pour couvrir l'affichage mono et multi-images.
    final imageCount = 1 + index % 4;
    final images = [
      for (var imageIndex = 0; imageIndex < imageCount; imageIndex++)
        ContentImage(
          fileName: fileNames[(index + imageIndex) % fileNames.length],
          width: _imageDimensions[(index + imageIndex) % _imageDimensions.length].$1,
          height: _imageDimensions[(index + imageIndex) % _imageDimensions.length].$2,
        ),
    ];

    final hasBody = index % 5 != 0;

    return ImageContent(
      id: UuidX.generate(),
      createdAt: createdAt,
      updatedAt: createdAt,
      authorId: authorId,
      senderId: 'seed-sender',
      origin: origin,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: bounce,
      sizeInBytes: isBroken ? 0 : 204800 * imageCount,
      flair: flair,
      images: images,
      title: 'Image #${index + 1}',
      body: hasBody ? _shortBodies[index % _shortBodies.length] : null,
    );
  }

  /// Construit un [LinkContent] avec des URLs valides, cassées ou malformées selon l'index.
  LinkContent _buildLinkContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
  ) {
    final isBroken = index % 3 == 0;
    final urls = isBroken ? _brokenUrls : _validUrls;
    final url = urls[index % urls.length];

    return LinkContent(
      id: UuidX.generate(),
      createdAt: createdAt,
      updatedAt: createdAt,
      authorId: authorId,
      senderId: 'seed-sender',
      origin: origin,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: bounce,
      sizeInBytes: 0,
      flair: flair,
      title: 'Lien #${index + 1}',
      url: url,
      ogImageUrl: isBroken ? null : 'https://www.leoxa.fr/wp-content/uploads/2023/02/flutter.png',
      ogTitle: isBroken ? null : 'OG Title #${index + 1}',
      ogDescription: isBroken ? null : 'Description Open Graph du lien #${index + 1}.',
    );
  }
}

/// Échecs possibles du [SeedContentsUsecase].
enum SeedContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la génération des contenus.
  unknown,
}

/// Paramètres du [SeedContentsUsecase].
class SeedContentsParams extends Params {
  /// Crée des [SeedContentsParams].
  ///
  /// - [count] : nombre de contenus à générer. Par défaut : 10 000.
  /// - [authorIds] : identifiants d'auteurs entre lesquels répartir les contenus au hasard.
  /// - [randomSeed] : graine du tirage des auteurs, pour un seed reproductible (tests). `null` pour un tirage aléatoire.
  const SeedContentsParams({this.count = 10000, this.authorIds = const [], this.randomSeed});

  /// Nombre de contenus factices à générer.
  final int count;

  /// Identifiants d'auteurs entre lesquels répartir les contenus au hasard.
  ///
  /// Le domaine des contenus ne connaît pas les utilisateurs : c'est
  /// l'appelant qui fournit les auteurs (utilisateurs factices, anonyme…).
  /// Vide : les contenus sont attribués à des identifiants fictifs sans profil.
  final List<String> authorIds;

  /// Graine du tirage des auteurs, `null` pour un tirage aléatoire.
  final int? randomSeed;
}
