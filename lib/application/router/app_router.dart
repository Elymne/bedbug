import 'package:bedbug/application/router/error_route_page.dart';
import 'package:bedbug/application/screens/create/create_screen.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:bedbug/application/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Chemin vers le splashscreen (page de démarrage de l'application).
const String splashPath = '/splash';

/// Chemin vers la page d'accueil.
const String homePath = '/home';

/// Chemin vers la page de création de contenu.
const String createPath = '/create';

/// Chemin vers la page des paramètres.
const String settingsPath = '/settings';

/// Durée du fondu entre les pages.
const Duration _fadeDuration = Duration(milliseconds: 400);

/// Construit une [CustomTransitionPage] avec un fondu doux pour [child].
CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: _fadeDuration,
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    ),
  );
}

/// Provider du [GoRouter] de l'application.
///
/// Le router se rafraîchit automatiquement lorsque [_RouterRefreshNotifier] le notifie, ce qui déclanche le redirect.
/// Pour l'instant, le notifier n'écoute rien mais je le garde au cas où.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: splashPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => null,
    errorPageBuilder: (context, state) => const NoTransitionPage(child: ErrorRoutePage(message: 'Page not found')),
    routes: [
      GoRoute(path: splashPath, pageBuilder: (context, state) => _fadePage(const SplashScreen())),
      GoRoute(path: homePath, pageBuilder: (context, state) => _fadePage(const HomeScreen())),
      GoRoute(path: createPath, pageBuilder: (context, state) => _fadePage(const CreateScreen())),
      GoRoute(path: settingsPath, pageBuilder: (context, state) => _fadePage(const SettingsScreen())),
    ],
  );
});

/// Notifier interne qui ne fait rien pour l'instant.
class _RouterRefreshNotifier extends ChangeNotifier {
  /// Crée un [_RouterRefreshNotifier] qui n'écoute rien pour l'instant.
  _RouterRefreshNotifier(Ref ref);
}
