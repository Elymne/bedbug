import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/own_contents_notifier.dart';
import 'package:bedbug/application/screens/home/home_feed_notifier.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/object_values/content_image.dart';
import 'package:bedbug/features/content/domain/usecases/prepare_content_images_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/infrastructure/og_metadata_service.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [PublishContentNotifier].
final publishContentNotifierProvider = AsyncNotifierProvider.autoDispose<PublishContentNotifier, void>(
  PublishContentNotifier.new,
);

/// Notifier gérant la publication d'un nouveau contenu, préparation comprise.
///
/// Publier peut prendre plusieurs secondes : recompresser jusqu'à dix
/// images, ou lire l'aperçu d'un lien sur le réseau. Tout ce travail se fait
/// ici, pendant que l'état est en chargement, pour que la page affiche son
/// écran de chargement du premier au dernier instant. Le résultat est
/// retourné à l'appelant : le contenu enregistré en cas de succès, pour
/// pouvoir l'ouvrir, ou le message d'erreur à afficher. Un succès recharge le
/// fil de la page d'accueil et la liste « Mes posts », où le contenu doit
/// apparaître.
class PublishContentNotifier extends AsyncNotifier<void> {
  /// Cas d'usage de sauvegarde d'un contenu.
  late final _saveContentUsecase = ref.read(saveContentUsecaseProvider);

  /// Cas d'usage de préparation des images d'un contenu image.
  late final _prepareContentImagesUsecase = ref.read(prepareContentImagesUsecaseProvider);

  /// Service de lecture de l'aperçu (Open Graph) d'un lien.
  late final _ogMetadataService = ref.read(ogMetadataServiceProvider);

  @override
  Future<void> build() async {}

  /// Publie [content], déjà complet (contenu texte).
  ///
  /// - [content] : contenu à publier.
  Future<Either<String, Content>> publish(Content content) async {
    state = const AsyncLoading();
    final result = await _save(content);
    state = const AsyncData(null);
    return result;
  }

  /// Prépare les images [sourcePaths], puis publie le contenu image construit à partir d'elles.
  ///
  /// - [sourcePaths] : chemins absolus des images choisies, dans l'ordre d'affichage.
  /// - [buildContent] : construit le contenu à partir des images préparées.
  Future<Either<String, Content>> publishImages({
    required List<String> sourcePaths,
    required ImageContent Function(List<ContentImage> images) buildContent,
  }) async {
    state = const AsyncLoading();
    final result = await _prepareContentImagesUsecase(PrepareContentImagesParams(sourcePaths: sourcePaths));
    final images = result.right;
    if (images == null) {
      state = const AsyncData(null);
      return Left(ref.l10n.createImageCompressionError);
    }
    final publishResult = await _save(buildContent(images));
    state = const AsyncData(null);
    return publishResult;
  }

  /// Lit l'aperçu du lien [url], puis publie le contenu lien construit à partir de lui.
  ///
  /// - [url] : adresse du lien partagé.
  /// - [buildContent] : construit le contenu à partir de l'aperçu lu.
  Future<Either<String, Content>> publishLink({
    required String url,
    required LinkContent Function(OgMetadata ogMetadata) buildContent,
  }) async {
    state = const AsyncLoading();
    final ogMetadata = await _ogMetadataService.fetch(url);
    final result = await _save(buildContent(ogMetadata));
    state = const AsyncData(null);
    return result;
  }

  /// Enregistre [content] et retourne le contenu enregistré, ou le message d'erreur à afficher.
  ///
  /// - [content] : contenu à enregistrer.
  Future<Either<String, Content>> _save(Content content) async {
    final result = await _saveContentUsecase(SaveContentParams(content: content));
    return result.fold(
      onFailure: (SaveContentFailure failure) {
        final message = switch (failure) {
          SaveContentFailure.storageError => ref.l10n.homeGetContentsStorageError,
          SaveContentFailure.unknown => ref.l10n.createSaveError,
        };
        return Left(message);
      },
      onSuccess: (Content savedContent) {
        ref.invalidate(homeFeedNotifierProvider);
        ref.invalidate(ownContentsNotifierProvider);
        return Right(savedContent);
      },
    );
  }
}
