import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ScreenSizeNotifier].
///
/// Marqué `keepAlive` — jamais détruit pendant la durée de vie de l'app.
final screenSizeNotifierProvider = NotifierProvider<ScreenSizeNotifier, Size>(ScreenSizeNotifier.new);

/// Notifier stockant les dimensions logiques de l'écran, initialisé une seule
/// fois au splashscreen via [init].
class ScreenSizeNotifier extends Notifier<Size> {
  @override
  Size build() {
    ref.keepAlive();
    return Size.zero;
  }

  /// Initialise les dimensions de l'écran.
  ///
  /// - [size] : dimensions logiques récupérées via [MediaQuery].
  void init(Size size) {
    state = size;
  }
}
