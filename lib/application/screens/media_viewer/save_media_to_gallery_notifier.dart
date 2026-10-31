import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/revealed_urls_notifier.dart';
import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/features/content/domain/usecases/fetch_media_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_media_to_gallery_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveMediaToGalleryNotifier].
final saveMediaToGalleryNotifierProvider = AsyncNotifierProvider.autoDispose<SaveMediaToGalleryNotifier, void>(
  SaveMediaToGalleryNotifier.new,
);

/// Notifier gérant l'enregistrement d'un média dans la galerie du téléphone, depuis la visionneuse.
///
/// Son état ne porte que le chargement en cours (pour désactiver le bouton
/// pendant le téléchargement et l'enregistrement) ; le résultat est retourné
/// directement à l'appelant, seul à savoir quoi afficher.
class SaveMediaToGalleryNotifier extends AsyncNotifier<void> {
  /// Cas d'usage de téléchargement d'un média.
  late final _fetchMediaUsecase = ref.read(fetchMediaUsecaseProvider);

  /// Cas d'usage d'enregistrement d'un média dans la galerie.
  late final _saveMediaToGalleryUsecase = ref.read(saveMediaToGalleryUsecaseProvider);

  @override
  Future<void> build() async {}

  /// Enregistre le média [url] dans la galerie et retourne `null` en cas de succès, ou le message d'erreur à afficher.
  ///
  /// Le média est téléchargé avec les mêmes règles que pour l'affichage : un
  /// domaine inconnu n'est accepté que si l'utilisateur l'a dévoilé.
  ///
  /// - [url] : adresse du média, telle que reçue.
  Future<String?> save(String url) async {
    state = const AsyncLoading();
    final trustSettings = await ref.read(trustSettingsNotifierProvider.future);
    final fetched = await _fetchMediaUsecase(
      FetchMediaParams(
        rawUrl: url,
        policy: trustSettings.mediaPolicy,
        isConfirmed: ref.read(revealedUrlsNotifierProvider).contains(url),
        maxBytes: maxGalleryMediaBytes,
      ),
    );
    final fetchedMedia = fetched.right;
    if (fetchedMedia == null) {
      state = const AsyncData(null);
      return fetched.left == FetchMediaFailure.tooLarge ? ref.l10n.mediaViewerTooLarge : ref.l10n.mediaUnavailable;
    }

    final result = await _saveMediaToGalleryUsecase(SaveMediaToGalleryParams(bytes: fetchedMedia.bytes));
    state = const AsyncData(null);

    return result.fold(
      onFailure: (SaveMediaToGalleryFailure failure) {
        return switch (failure) {
          SaveMediaToGalleryFailure.unsupportedFormat => ref.l10n.mediaViewerUnsupportedFormat,
          SaveMediaToGalleryFailure.accessDenied => ref.l10n.mediaViewerAccessDenied,
          SaveMediaToGalleryFailure.saveError => ref.l10n.mediaViewerSaveError,
        };
      },
      onSuccess: (_) {
        return null;
      },
    );
  }
}
