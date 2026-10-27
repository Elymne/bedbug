import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rayon des coins arrondis de l'aperçu.
const double _kRadius = 8;

/// Image d'aperçu (Open Graph) d'un lien, qui ne prend aucune place si son domaine n'est pas accepté.
///
/// L'aperçu n'est qu'une décoration : contrairement aux médias d'un
/// contenu, il n'est ni voilé ni signalé quand son domaine est inconnu, il
/// disparaît simplement, sans laisser de trou dans la mise en page. Un
/// aperçu en greylist reste flouté, comme tout média de la greylist.
class AppLinkPreviewImage extends ConsumerWidget {
  /// Crée un [AppLinkPreviewImage].
  ///
  /// - [url] : adresse de l'image d'aperçu, `null` si le lien n'en a pas.
  /// - [width] : largeur de l'aperçu.
  /// - [height] : hauteur de l'aperçu.
  const AppLinkPreviewImage({super.key, required this.url, required this.width, required this.height});

  /// Adresse de l'image d'aperçu, `null` si le lien n'en a pas.
  final String? url;

  /// Largeur de l'aperçu.
  final double width;

  /// Hauteur de l'aperçu.
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustSettingsNotifierWatcher = ref.watch(trustSettingsNotifierProvider);
    final previewUrl = url;
    final trust = trustSettingsNotifierWatcher.value?.mediaPolicy.evaluate(previewUrl ?? '');
    if (previewUrl == null || (trust != UrlTrust.trusted && trust != UrlTrust.grey)) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_kRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: AppRemoteMedia(
          media: ContentMedia(url: previewUrl, kind: MediaKind.image),
        ),
      ),
    );
  }
}
