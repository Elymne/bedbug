import 'package:bedbug/application/notifiers/local_signature_notifier.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SplashNotifier].
final splashNotifierProvider = AsyncNotifierProvider<SplashNotifier, SplashState>(SplashNotifier.new);

/// Notifier gérant l'état du splashscreen.
class SplashNotifier extends AsyncNotifier<SplashState> {
  @override
  Future<SplashState> build() async {
    final localSignature = await ref.read(localSignatureNotifierProvider.future);
    await Future<void>.delayed(const Duration(seconds: 4));

    // Une lecture en échec ne dit pas que la signature manque : envoyer sur la
    // création risquerait de remplacer une signature qui existe bien.
    final isSignatureMissing = localSignature.signature == null && localSignature.failureMessage == null;
    return SplashState(isSignatureMissing: isSignatureMissing);
  }
}

/// État du [SplashNotifier].
class SplashState extends NotifierState {
  /// Crée un [SplashState].
  ///
  /// - [isSignatureMissing] : `true` si l'appareil n'a encore aucune signature.
  /// - [failureMessage] : message d'erreur éventuel.
  SplashState({this.isSignatureMissing = false, super.failureMessage});

  /// Indique que l'appareil n'a encore aucune signature, à créer avant d'aller plus loin.
  final bool isSignatureMissing;
}
