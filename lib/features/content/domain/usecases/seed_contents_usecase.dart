import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_priority.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SeedContentsUsecase].
final seedContentsUsecaseProvider = Provider<SeedContentsUsecase>(
  (ref) => SeedContentsUsecase(ref.read(contentRepositoryProvider)),
);

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
  SeedContentsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  /// Nombre d'items écrits en une seule opération Hive.
  static const int _batchSize = 500;

  @override
  Future<Either<SeedContentsFailure, void>> call(SeedContentsParams params) async {
    try {
      final now = DateTime.now();
      final batch = <dynamic>[];

      for (var index = 0; index < params.count; index++) {
        final createdAt = now.subtract(Duration(minutes: index));
        final priority = ContentPriority.values[index % ContentPriority.values.length];
        final bounce = index % 11;
        final subId = index % 10 < 3 ? 'seed-sub-${index % 5}' : null;

        batch.add(_buildContent(index, createdAt, priority, bounce, subId));

        if (batch.length == _batchSize) {
          await _contentRepository.addMany(List.from(batch));
          batch.clear();
        }
      }

      if (batch.isNotEmpty) {
        await _contentRepository.addMany(List.from(batch));
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

  /// Construit un contenu factice selon le modulo de [index] pour distribuer les types.
  ///
  /// - index % 10 in [0..3] → [TextContent] (40 %)
  /// - index % 10 in [4..6] → [ImageContent] (30 %)
  /// - index % 10 in [7..9] → [LinkContent] (30 %)
  dynamic _buildContent(int index, DateTime createdAt, ContentPriority priority, int bounce, String? subId) {
    final bucket = index % 10;

    if (bucket <= 3) {
      return _buildTextContent(index, createdAt, priority, bounce, subId);
    }

    if (bucket <= 6) {
      return _buildImageContent(index, createdAt, priority, bounce, subId);
    }

    return _buildLinkContent(index, createdAt, priority, bounce, subId);
  }

  /// Construit un [TextContent] avec titre court, long, ou corps vide selon l'index.
  TextContent _buildTextContent(int index, DateTime createdAt, ContentPriority priority, int bounce, String? subId) {
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
      authorId: 'seed-author-${index % 5}',
      senderId: 'seed-sender',
      priority: priority,
      bounce: bounce,
      sizeInBytes: body.length,
      subId: subId,
      title: title,
      body: body,
    );
  }

  /// Construit un [ImageContent] avec des noms de fichiers valides ou cassés selon l'index.
  ImageContent _buildImageContent(int index, DateTime createdAt, ContentPriority priority, int bounce, String? subId) {
    final isBroken = index % 4 == 0;
    final fileNames = isBroken ? _brokenImageFileNames : _validImageFileNames;
    final fileName = fileNames[index % fileNames.length];
    final dimensions = _imageDimensions[index % _imageDimensions.length];

    final hasBody = index % 5 != 0;

    return ImageContent(
      id: UuidX.generate(),
      createdAt: createdAt,
      updatedAt: createdAt,
      authorId: 'seed-author-${index % 5}',
      senderId: 'seed-sender',
      priority: priority,
      bounce: bounce,
      sizeInBytes: isBroken ? 0 : 204800,
      subId: subId,
      fileName: fileName,
      imageWidth: dimensions.$1,
      imageHeight: dimensions.$2,
      title: 'Image #${index + 1}',
      body: hasBody ? _shortBodies[index % _shortBodies.length] : null,
    );
  }

  /// Construit un [LinkContent] avec des URLs valides, cassées ou malformées selon l'index.
  LinkContent _buildLinkContent(int index, DateTime createdAt, ContentPriority priority, int bounce, String? subId) {
    final isBroken = index % 3 == 0;
    final urls = isBroken ? _brokenUrls : _validUrls;
    final url = urls[index % urls.length];

    return LinkContent(
      id: UuidX.generate(),
      createdAt: createdAt,
      updatedAt: createdAt,
      authorId: 'seed-author-${index % 5}',
      senderId: 'seed-sender',
      priority: priority,
      bounce: bounce,
      sizeInBytes: 0,
      subId: subId,
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
  const SeedContentsParams({this.count = 10000});

  /// Nombre de contenus factices à générer.
  final int count;
}
