import 'package:bedbug/features/content/domain/usecases/clear_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/features/signature/domain/usecases/seed_signatures_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SplashNotifier].
final splashNotifierProvider = AsyncNotifierProvider<SplashNotifier, SplashState>(SplashNotifier.new);

/// Notifier gérant l'état du splashscreen.
class SplashNotifier extends AsyncNotifier<SplashState> {
  late final _clearContentsUsecase = ref.read(clearContentsUsecaseProvider);
  late final _seedSignaturesUsecase = ref.read(seedSignaturesUsecaseProvider);
  late final _seedContentsUsecase = ref.read(seedContentsUsecaseProvider);

  @override
  Future<SplashState> build() async {
    await Future.wait([Future<void>.delayed(const Duration(seconds: 4)), _reseed()]);
    return SplashState();
  }

  /// Remplace les données de démo : vide les contenus, régénère les utilisateurs factices, puis les contenus factices.
  ///
  /// Les contenus sont répartis au hasard entre les utilisateurs factices et
  /// l'anonyme, pour que la recherche par utilisateur et l'affichage des
  /// auteurs aient de quoi être testés. Si la génération des utilisateurs
  /// échoue, les contenus sont tout de même générés, avec des auteurs fictifs.
  Future<void> _reseed() async {
    await _clearContentsUsecase(const NoParams());
    final seedSignaturesResult = await _seedSignaturesUsecase(const SeedSignaturesParams());
    final authorIds = [...?seedSignaturesResult.right, anonymousSignatureId];
    await _seedContentsUsecase(SeedContentsParams(authorIds: authorIds));
  }
}

/// État du [SplashNotifier].
class SplashState extends NotifierState {
  /// Crée un [SplashState] avec un éventuel [failureMessage].
  SplashState({super.failureMessage});
}
