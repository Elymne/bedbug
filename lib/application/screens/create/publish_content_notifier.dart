import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/own_contents_notifier.dart';
import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/screens/home/home_feed_notifier.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/infrastructure/og_metadata_service.dart';
import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [PublishContentNotifier].
final publishContentNotifierProvider = AsyncNotifierProvider.autoDispose<PublishContentNotifier, void>(
  PublishContentNotifier.new,
);

/// Notifier gérant la publication d'un nouveau contenu, préparation comprise.
///
/// Publier un lien peut prendre quelques secondes, le temps de lire son
/// aperçu sur le réseau. Tout ce travail se fait ici, pendant que l'état est
/// en chargement, pour que la page affiche son écran de chargement du
/// premier au dernier instant. Le résultat est retourné à l'appelant : le
/// contenu enregistré en cas de succès, pour pouvoir l'ouvrir, ou le message
/// d'erreur à afficher. Un succès recharge le fil de la page d'accueil et la
/// liste « Mes posts », où le contenu doit apparaître.
class PublishContentNotifier extends AsyncNotifier<void> {
  /// Cas d'usage de sauvegarde d'un contenu.
  late final _saveContentUsecase = ref.read(saveContentUsecaseProvider);

  /// Service de lecture de l'aperçu (Open Graph) d'un lien.
  late final _ogMetadataService = ref.read(ogMetadataServiceProvider);

  @override
  Future<void> build() async {}

  /// Publie [content], déjà complet (contenu texte ou média).
  ///
  /// - [content] : contenu à publier.
  Future<Either<String, Content>> publish(Content content) async {
    state = const AsyncLoading();
    final result = await _save(content);
    state = const AsyncData(null);
    return result;
  }

  /// Lit l'aperçu du lien [url] s'il est de confiance, puis publie le contenu lien construit à partir de lui.
  ///
  /// Lire l'aperçu, c'est contacter le site du lien sans que l'auteur ait
  /// rien ouvert : ce n'est fait que pour un domaine de sa whitelist de
  /// liens. Sinon, le lien est publié sans aperçu.
  ///
  /// - [url] : adresse du lien partagé.
  /// - [buildContent] : construit le contenu à partir de l'aperçu lu.
  Future<Either<String, Content>> publishLink({
    required String url,
    required LinkContent Function(OgMetadata ogMetadata) buildContent,
  }) async {
    state = const AsyncLoading();
    final trustSettings = await ref.read(trustSettingsNotifierProvider.future);
    var ogMetadata = const OgMetadata();
    final safeUrl = SafeUrl.tryParse(url);
    if (safeUrl != null && trustSettings.linkPolicy.evaluate(safeUrl.url) == UrlTrust.trusted) {
      ogMetadata = await _ogMetadataService.fetch(safeUrl.url);
    }
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
