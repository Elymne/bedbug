import 'package:bedbug/application/router/error_route_page.dart';
import 'package:bedbug/application/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Chemin vers le splashscreen (page de démarrage de l'application).
const String splashPath = '/splash';

/// Chemin vers la page de chargement et déchiffrage de contenu.
const String loadPath = '/load';

/// Chemin vers la home page mais imo, j'vais pas en mettre hihihi.
const String homeScreen = '/home';

/// Provider du [GoRouter] de l'application.
///
/// Le router se rafraîchit automatiquement lorsque l'état de [CurrentUserNotifier]
/// change, déclenchant la réévaluation de la redirection.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: splashPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      return null;
      // TODO : In case I would need to do something here but I don't think so.
    },
    errorPageBuilder: (context, state) =>
        NoTransitionPage(child: ErrorRoutePage(message: "Page not found")),
    routes: [
      GoRoute(
        path: splashPath,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
    ],
  );
});

/// Notifier interne qui ne fait rien pour l'instant.
class _RouterRefreshNotifier extends ChangeNotifier {
  /// Crée un [_RouterRefreshNotifier] en écoutant [currentUserNotifierProvider].
  _RouterRefreshNotifier(Ref ref);
}
