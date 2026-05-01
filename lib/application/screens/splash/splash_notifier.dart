import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SplashNotifier].
final splashNotifierProvider =
    AsyncNotifierProvider<SplashNotifier, SplashState>(SplashNotifier.new);

/// Notifier gérant l'état du splashscreen.
class SplashNotifier extends AsyncNotifier<SplashState> {
  @override
  Future<SplashState> build() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    return SplashState();
  }
}

/// État du [SplashNotifier].
class SplashState extends NotifierState {
  /// Crée un [SplashState] avec un éventuel [failureMessage].
  SplashState({super.failureMessage});
}
