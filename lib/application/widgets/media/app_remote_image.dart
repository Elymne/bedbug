import 'package:bedbug/application/providers/trusted_media_loader_provider.dart';
import 'package:bedbug/application/widgets/media/app_media_placeholder.dart';
import 'package:bedbug/application/widgets/media/trusted_network_image.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Image ou gif distant, chargé par le [TrustedMediaLoader], qui remplit la place que lui donne son parent.
///
/// Ne décide pas si l'image peut être chargée : c'est le rôle de
/// `AppRemoteMedia`, qui ne construit ce widget qu'une fois l'image
/// acceptée. L'image est décodée à la largeur de l'écran au plus : une
/// image géante envoyée par un pair ne peut pas saturer la mémoire.
class AppRemoteImage extends ConsumerWidget {
  /// Crée un [AppRemoteImage].
  ///
  /// - [url] : adresse de l'image, telle que reçue.
  /// - [isConfirmed] : `true` si l'utilisateur a confirmé vouloir l'afficher malgré un domaine inconnu.
  /// - [fit] : façon de faire tenir l'image dans sa place (défaut [BoxFit.cover]).
  const AppRemoteImage({super.key, required this.url, required this.isConfirmed, this.fit = BoxFit.cover});

  /// Adresse de l'image, telle que reçue.
  final String url;

  /// Indique si l'utilisateur a confirmé vouloir afficher l'image malgré un domaine inconnu.
  final bool isConfirmed;

  /// Façon de faire tenir l'image dans sa place.
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);

    return Image(
      image: ResizeImage.resizeIfNeeded(
        (mediaQuery.size.width * mediaQuery.devicePixelRatio).round(),
        null,
        TrustedNetworkImage(url: url, isConfirmed: isConfirmed, loader: ref.read(trustedMediaLoaderProvider)),
      ),
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return const AppMediaPlaceholder(icon: Icons.image_outlined);
      },
      errorBuilder: (context, error, stackTrace) {
        return AppMediaPlaceholder(icon: Icons.broken_image_outlined, label: context.loc.mediaUnavailable);
      },
    );
  }
}
