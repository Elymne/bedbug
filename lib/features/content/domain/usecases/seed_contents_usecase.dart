import 'dart:math';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/services/media_kind_service.dart';
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
  return SeedContentsUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(mediaKindServiceProvider),
  );
});

/// Liens factices, avec leur image d'aperçu, couvrant chaque niveau de confiance des listes par défaut.
///
/// À retirer avant la préprod, avec le reste du seed.
const List<(String, String?)> _seedLinks = [
  // Domaine de confiance, aperçu de confiance (avec redirection vers le CDN de picsum).
  ('https://fr.wikipedia.org/wiki/Punaise_de_lit', 'https://picsum.photos/id/1025/600/400'),
  ('https://www.youtube.com/watch?v=aqz-KE-bpKQ', 'https://picsum.photos/id/1062/600/400'),
  // Domaine de confiance, aperçu en greylist (flouté).
  ('https://github.com/Elymne/bedbug', 'https://placehold.co/600x400/png?text=greylist'),
  // Domaine de confiance, aperçu sur un domaine inconnu (omis).
  ('https://github.com/flutter/flutter', 'https://www.leoxa.fr/wp-content/uploads/2023/02/flutter.png'),
  // Lien en greylist.
  ('https://www.reddit.com/r/FlutterDev/', null),
  // Lien vers un domaine inconnu (masqué par défaut).
  ('https://flutter.dev', null),
  // Lien piégé : toujours masqué.
  ('https://github.com@evil.example/', null),
];

/// Jeux de médias factices, couvrant les cas de rendu : image, gif, vidéo, plusieurs médias, 404, greylist,
/// domaine inconnu et adresse piégée.
///
/// Sources choisies pour leur fiabilité (placeholders, vidéos de test). À
/// retirer avant la préprod, avec le reste du seed.
const List<List<String>> _seedMediaSets = [
  // Image de confiance, servie après une redirection vers fastly.picsum.photos.
  ['https://picsum.photos/id/237/800/600'],
  // Gif de confiance.
  ['https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif'],
  // Vidéo de confiance.
  ['https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4'],
  // Plusieurs médias de confiance, de proportions variées.
  [
    'https://picsum.photos/id/1015/900/600',
    'https://picsum.photos/id/1011/600/900',
    'https://upload.wikimedia.org/wikipedia/commons/a/a7/Camponotus_flavomarginatus_ant.jpg',
    'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4',
  ],
  // Domaine de confiance, mais le média n'existe pas (404).
  ['https://picsum.photos/id/99999/600/400'],
  ['https://upload.wikimedia.org/wikipedia/commons/0/00/Bedbug_n_existe_pas_404.png'],
  // Greylist : flouté, affiché sur confirmation.
  ['https://placehold.co/600x400/png?text=greylist'],
  // Mélange de confiance et de greylist.
  ['https://picsum.photos/id/1040/800/500', 'https://placehold.co/400x600/png?text=greylist'],
  // Domaine inconnu : masqué par défaut, flouté si l'utilisateur change le réglage.
  ['https://images.example-inconnu.com/photo.jpg'],
  // Adresse piégée : toujours masquée.
  ['https://picsum.photos@evil.example/id/237/800/600'],
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
  SeedContentsUsecase(this._contentRepository, this._storageRepository, this._mediaKindService);

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;
  final MediaKindService _mediaKindService;

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
        final content = _buildContent(index, createdAt, origin, bounce, flair, authorId, _pickTags(random));
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

  /// Tire au hasard de 0 à 2 tags distincts pour un contenu factice.
  ///
  /// Environ 30 % des contenus n'ont aucun tag, 50 % en ont un et 20 % en ont
  /// deux : les tuiles du fil montrent ainsi des contenus avec et sans tag.
  ///
  /// - [random] : générateur partagé par tout le seed.
  List<Tag> _pickTags(Random random) {
    final roll = random.nextDouble();
    final count = roll < 0.3 ? 0 : (roll < 0.8 ? 1 : 2);
    return ([...Tag.values]..shuffle(random)).take(count).toList();
  }

  /// Construit un contenu factice selon le modulo de [index] pour distribuer les types.
  ///
  /// - index % 10 in [0..3] → [TextContent] (40 %)
  /// - index % 10 in [4..6] → [MediaContent] (30 %)
  /// - index % 10 in [7..9] → [LinkContent] (30 %)
  Content _buildContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
    List<Tag> tags,
  ) {
    final bucket = index % 10;

    if (bucket <= 3) {
      return _buildTextContent(index, createdAt, origin, bounce, flair, authorId, tags);
    }

    if (bucket <= 6) {
      return _buildMediaContent(index, createdAt, origin, bounce, flair, authorId, tags);
    }

    return _buildLinkContent(index, createdAt, origin, bounce, flair, authorId, tags);
  }

  /// Construit un [TextContent] avec titre court, long, ou corps vide selon l'index.
  TextContent _buildTextContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
    List<Tag> tags,
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
      tags: tags,
      title: title,
      body: body,
    );
  }

  /// Construit un [MediaContent] à partir de l'un des jeux de médias factices, choisi selon l'index.
  MediaContent _buildMediaContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
    List<Tag> tags,
  ) {
    final mediaUrls = _seedMediaSets[index % _seedMediaSets.length];
    final hasBody = index % 5 != 0;

    return MediaContent(
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
      sizeInBytes: mediaUrls.fold(0, (total, url) => total + url.length),
      flair: flair,
      tags: tags,
      media: [for (final url in mediaUrls) _mediaKindService.mediaOf(url)],
      title: 'Média #${index + 1}',
      body: hasBody ? _shortBodies[index % _shortBodies.length] : null,
    );
  }

  /// Construit un [LinkContent] à partir de l'un des liens factices, choisi selon l'index.
  LinkContent _buildLinkContent(
    int index,
    DateTime createdAt,
    ContentOrigin origin,
    int bounce,
    String flair,
    String authorId,
    List<Tag> tags,
  ) {
    final (url, ogImageUrl) = _seedLinks[index % _seedLinks.length];
    final hasPreview = ogImageUrl != null;

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
      tags: tags,
      title: 'Lien #${index + 1}',
      url: url,
      ogImageUrl: ogImageUrl,
      ogTitle: hasPreview ? 'OG Title #${index + 1}' : null,
      ogDescription: hasPreview ? 'Description Open Graph du lien #${index + 1}.' : null,
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
