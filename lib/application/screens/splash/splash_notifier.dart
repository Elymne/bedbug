import 'package:bedbug/features/content/domain/usecases/clear_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SplashNotifier].
final splashNotifierProvider = AsyncNotifierProvider<SplashNotifier, SplashState>(SplashNotifier.new);

/// Notifier gérant l'état du splashscreen.
class SplashNotifier extends AsyncNotifier<SplashState> {
  late final _clearContentsUsecase = ref.read(clearContentsUsecaseProvider);
  late final _seedContentsUsecase = ref.read(seedContentsUsecaseProvider);

  @override
  Future<SplashState> build() async {
    await Future.wait([
      Future<void>.delayed(const Duration(seconds: 4)),
      _clearContentsUsecase(const NoParams()).then((_) => _seedContentsUsecase(const SeedContentsParams())),
    ]);
    return SplashState();
  }
}

/// État du [SplashNotifier].
class SplashState extends NotifierState {
  /// Crée un [SplashState] avec un éventuel [failureMessage].
  SplashState({super.failureMessage});
}
