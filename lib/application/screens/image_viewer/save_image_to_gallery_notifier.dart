import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/usecases/save_image_to_gallery_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveImageToGalleryNotifier].
final saveImageToGalleryNotifierProvider = AsyncNotifierProvider.autoDispose<SaveImageToGalleryNotifier, void>(
  SaveImageToGalleryNotifier.new,
);

/// Notifier gérant l'enregistrement d'une image dans la galerie du téléphone, depuis la visionneuse.
///
/// Son état ne porte que le chargement en cours (pour désactiver le bouton
/// pendant la conversion et l'enregistrement) ; le résultat est retourné
/// directement à l'appelant, seul à savoir quoi afficher.
class SaveImageToGalleryNotifier extends AsyncNotifier<void> {
  /// Cas d'usage d'enregistrement d'une image dans la galerie.
  late final _saveImageToGalleryUsecase = ref.read(saveImageToGalleryUsecaseProvider);

  @override
  Future<void> build() async {}

  /// Enregistre l'image [sourcePath] dans la galerie et retourne `null` en cas de succès, ou le message d'erreur à afficher.
  ///
  /// - [sourcePath] : chemin absolu de l'image à enregistrer.
  Future<String?> save(String sourcePath) async {
    state = const AsyncLoading();
    final result = await _saveImageToGalleryUsecase(SaveImageToGalleryParams(sourcePath: sourcePath));
    state = const AsyncData(null);

    return result.fold(
      onFailure: (SaveImageToGalleryFailure failure) {
        return switch (failure) {
          SaveImageToGalleryFailure.accessDenied => ref.l10n.imageViewerAccessDenied,
          SaveImageToGalleryFailure.saveError => ref.l10n.imageViewerSaveError,
          SaveImageToGalleryFailure.unknown => ref.l10n.imageViewerSaveError,
        };
      },
      onSuccess: (_) {
        return null;
      },
    );
  }
}
