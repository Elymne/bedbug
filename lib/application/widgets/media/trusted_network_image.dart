import 'dart:ui' as ui;

import 'package:bedbug/application/providers/trusted_media_loader_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Image distante chargée par le [TrustedMediaLoader], jamais directement par Flutter.
///
/// `NetworkImage` suit les redirections sans rien vérifier : un domaine de
/// confiance pourrait ainsi faire charger une image depuis n'importe quel
/// site. Cette image délègue tout le téléchargement au [TrustedMediaLoader],
/// qui vérifie chaque redirection, et profite du cache d'images de Flutter.
@immutable
class TrustedNetworkImage extends ImageProvider<TrustedNetworkImage> {
  /// Crée une [TrustedNetworkImage].
  ///
  /// - [url] : adresse de l'image, telle que reçue.
  /// - [isConfirmed] : `true` si l'utilisateur a confirmé vouloir l'afficher malgré un domaine inconnu.
  /// - [loader] : téléchargeur à utiliser.
  const TrustedNetworkImage({required this.url, required this.isConfirmed, required this.loader});

  /// Adresse de l'image, telle que reçue.
  final String url;

  /// Indique si l'utilisateur a confirmé vouloir afficher l'image malgré un domaine inconnu.
  final bool isConfirmed;

  /// Téléchargeur à utiliser. Ne compte pas dans l'égalité : deux images de même adresse partagent le cache.
  final TrustedMediaLoader loader;

  @override
  Future<TrustedNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TrustedNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(TrustedNetworkImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(codec: _loadCodec(decode), scale: 1, debugLabel: url);
  }

  /// Télécharge l'image via le [loader] puis la décode, gifs animés compris.
  Future<ui.Codec> _loadCodec(ImageDecoderCallback decode) async {
    final bytes = await loader.load(url, isConfirmed: isConfirmed);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is TrustedNetworkImage && other.url == url && other.isConfirmed == isConfirmed;
  }

  @override
  int get hashCode {
    return Object.hash(url, isConfirmed);
  }
}
