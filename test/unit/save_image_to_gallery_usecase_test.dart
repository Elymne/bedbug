import 'package:bedbug/features/content/domain/gateways/image_gallery_gateway.dart';
import 'package:bedbug/features/content/domain/usecases/save_image_to_gallery_usecase.dart';
import 'package:bedbug/shared/exceptions/gallery_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Galerie factice qui réussit, ou échoue avec l'erreur fournie.
class _FakeImageGalleryGateway implements ImageGalleryGateway {
  /// Crée un [_FakeImageGalleryGateway].
  ///
  /// - [error] : erreur levée à l'enregistrement, `null` pour réussir.
  _FakeImageGalleryGateway([this.error]);

  /// Erreur levée à l'enregistrement, `null` pour réussir.
  final Object? error;

  /// Chemins des images enregistrées.
  final List<String> savedPaths = [];

  @override
  Future<void> saveImage(String sourcePath) async {
    final error = this.error;
    if (error != null) {
      throw error;
    }
    savedPaths.add(sourcePath);
  }
}

void main() {
  test('enregistre l\'image dans la galerie', () async {
    final gateway = _FakeImageGalleryGateway();

    final result = await SaveImageToGalleryUsecase(gateway)(const SaveImageToGalleryParams(sourcePath: '/a.webp'));

    expect(result.isSuccess, isTrue);
    expect(gateway.savedPaths, ['/a.webp']);
  });

  test('distingue un refus d\'accès des autres échecs', () async {
    final denied = await SaveImageToGalleryUsecase(
      _FakeImageGalleryGateway(const GalleryException('test', 'denied', isAccessDenied: true)),
    )(const SaveImageToGalleryParams(sourcePath: '/a.webp'));
    final failed = await SaveImageToGalleryUsecase(_FakeImageGalleryGateway(const GalleryException('test', 'full')))(
      const SaveImageToGalleryParams(sourcePath: '/a.webp'),
    );
    final crashed = await SaveImageToGalleryUsecase(_FakeImageGalleryGateway(StateError('boom')))(
      const SaveImageToGalleryParams(sourcePath: '/a.webp'),
    );

    expect(denied.left, SaveImageToGalleryFailure.accessDenied);
    expect(failed.left, SaveImageToGalleryFailure.saveError);
    expect(crashed.left, SaveImageToGalleryFailure.unknown);
  });
}
