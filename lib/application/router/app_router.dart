import 'package:bedbug/application/router/error_route_page.dart';
import 'package:bedbug/application/screens/avatar_picker/avatar_picker_screen.dart';
import 'package:bedbug/application/screens/content_detail/drawing_content_detail_screen.dart';
import 'package:bedbug/application/screens/content_detail/link_content_detail_screen.dart';
import 'package:bedbug/application/screens/content_detail/media_content_detail_screen.dart';
import 'package:bedbug/application/screens/content_detail/text_content_detail_screen.dart';
import 'package:bedbug/application/screens/create/create_screen.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor_screen.dart';
import 'package:bedbug/application/screens/drawing_format/drawing_format_screen.dart';
import 'package:bedbug/application/screens/drawing_viewer/drawing_viewer_screen.dart';
import 'package:bedbug/application/screens/exchange/exchange_screen.dart';
import 'package:bedbug/application/screens/exchange_logs/exchange_logs_screen.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/screens/media_viewer/media_viewer_screen.dart';
import 'package:bedbug/application/screens/search/search_screen.dart';
import 'package:bedbug/application/screens/search_results/search_criteria.dart';
import 'package:bedbug/application/screens/search_results/search_results_screen.dart';
import 'package:bedbug/application/screens/select_options/select_options_screen.dart';
import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:bedbug/application/screens/signature/signature_screen.dart';
import 'package:bedbug/application/screens/signature_setup/signature_setup_screen.dart';
import 'package:bedbug/application/screens/splash/splash_screen.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Chemin vers le splashscreen (page de démarrage de l'application).
const String splashPath = '/splash';

/// Chemin vers la page d'accueil.
const String homePath = '/home';

/// Chemin vers la page de création de contenu.
const String createPath = '/create';

/// Chemin vers la page d'activation de l'échange entre téléphones.
const String exchangePath = '/exchange';

/// Chemin vers la page des paramètres.
const String settingsPath = '/settings';

/// Chemin vers la page de debug du journal des échanges.
const String exchangeLogsPath = '/settings/exchange-logs';

/// Chemin vers la page de création de la signature, proposée tant que l'appareil n'en a aucune.
const String signatureSetupPath = '/signature-setup';

/// Chemin vers la page de choix d'une icône de profil.
///
/// Déclarée au premier niveau : le formulaire de signature l'ouvre aussi bien
/// depuis les paramètres que depuis la création de la signature, qui ne doit
/// pas empiler la page des paramètres. La page renvoie le kaomoji choisi via
/// `context.pop`, à récupérer avec `context.push<String>(avatarPickerPath)`.
const String avatarPickerPath = '/avatar-picker';

/// Chemin vers la page listant les options d'une `AppSelectBox`.
///
/// Les options sont transmises via `extra` (`SelectOptionsParams`), et la
/// valeur choisie est retournée au `pop`.
const String selectOptionsPath = '/select-options';

/// Chemin vers la page de choix du bedbug d'une réaction.
///
/// Même page que [avatarPickerPath], avec un titre propre aux réactions. Le
/// kaomoji choisi est renvoyé via `context.pop`, à récupérer avec
/// `context.push<String>(reactionPickerPath)`.
const String reactionPickerPath = '/reaction-picker';

/// Chemin vers la page de recherche dédiée.
const String searchPath = '/search';

/// Chemin vers la page de résultats de recherche.
///
/// Le critère est transmis en paramètre de requête : [searchFlairParam] pour
/// un flair choisi parmi les suggestions, [searchQueryParam] pour une
/// recherche globale. Une signature choisie ouvre, elle, sa page dédiée
/// ([signaturePath]).
const String searchResultsPath = '/search/results';

/// Paramètre de requête de [searchResultsPath] portant le flair choisi.
const String searchFlairParam = 'flair';

/// Paramètre de requête de [searchResultsPath] portant le texte d'une recherche globale.
const String searchQueryParam = 'q';

/// Préfixe du chemin des pages de signature : `/signatures/<identifiant>`.
///
/// Naviguer avec `context.push('$signaturesPath/${signature.id}')`.
const String signaturesPath = '/signatures';

/// Chemin de la page d'une signature, identifiant en paramètre de chemin.
const String signaturePath = '$signaturesPath/:id';

/// Chemin vers la visionneuse plein écran des médias d'un contenu.
///
/// Les médias et la position de départ sont transmis via `extra`
/// (`MediaViewerParams`).
const String mediaViewerPath = '/media-viewer';

/// Chemin vers l'éditeur de dessin.
///
/// Le dessin à reprendre est transmis via `extra` (`Drawing`), et le dessin
/// validé est retourné au `pop`.
const String drawingEditorPath = '/drawing-editor';

/// Chemin vers le choix de la surface d'un nouveau dessin, avant l'éditeur.
///
/// Le dessin vide à la surface choisie est retourné au `pop`.
const String drawingFormatPath = '/drawing-format';

/// Chemin vers la visionneuse plein écran d'un dessin.
///
/// Le dessin est transmis via `extra` (`DrawingViewerParams`).
const String drawingViewerPath = '/drawing-viewer';

/// Chemin vers la page de détail d'un contenu.
///
/// Le contenu est transmis via `extra` (pas de fetch par id pour l'instant).
const String contentDetailPath = '/content-detail';

/// Durée du fondu entre les pages.
const Duration _fadeDuration = Duration(milliseconds: 400);

/// Construit une [CustomTransitionPage] avec un fondu doux pour [child].
CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: _fadeDuration,
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
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
      GoRoute(path: signatureSetupPath, pageBuilder: (context, state) => _fadePage(const SignatureSetupScreen())),
      GoRoute(path: homePath, pageBuilder: (context, state) => _fadePage(const HomeScreen())),
      GoRoute(path: createPath, pageBuilder: (context, state) => _fadePage(const CreateScreen())),
      GoRoute(path: exchangePath, pageBuilder: (context, state) => _fadePage(const ExchangeScreen())),
      GoRoute(
        path: settingsPath,
        pageBuilder: (context, state) => _fadePage(const SettingsScreen()),
        routes: [
          GoRoute(path: 'exchange-logs', pageBuilder: (context, state) => _fadePage(const ExchangeLogsScreen())),
        ],
      ),
      GoRoute(path: avatarPickerPath, pageBuilder: (context, state) => _fadePage(const AvatarPickerScreen())),
      GoRoute(
        path: selectOptionsPath,
        pageBuilder: (context, state) => _fadePage(SelectOptionsScreen(params: state.extra! as SelectOptionsParams)),
      ),
      GoRoute(
        path: reactionPickerPath,
        pageBuilder: (context, state) {
          return _fadePage(AvatarPickerScreen(title: context.loc.reactionPickerTitle));
        },
      ),
      GoRoute(
        path: searchPath,
        pageBuilder: (context, state) => _fadePage(const SearchScreen()),
        routes: [
          GoRoute(
            path: 'results',
            pageBuilder: (context, state) => _fadePage(_searchResultsScreenFor(state.uri.queryParameters)),
          ),
        ],
      ),
      GoRoute(
        path: signaturePath,
        pageBuilder: (context, state) => _fadePage(SignatureScreen(signatureId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: mediaViewerPath,
        pageBuilder: (context, state) => _fadePage(MediaViewerScreen(params: state.extra! as MediaViewerParams)),
      ),
      GoRoute(
        path: drawingEditorPath,
        pageBuilder: (context, state) {
          return _fadePage(DrawingEditorScreen(initialDrawing: state.extra as Drawing? ?? const Drawing.empty()));
        },
      ),
      GoRoute(path: drawingFormatPath, pageBuilder: (context, state) => _fadePage(const DrawingFormatScreen())),
      GoRoute(
        path: drawingViewerPath,
        pageBuilder: (context, state) => _fadePage(DrawingViewerScreen(params: state.extra! as DrawingViewerParams)),
      ),
      GoRoute(
        path: contentDetailPath,
        pageBuilder: (context, state) => _fadePage(_contentDetailScreenFor(state.extra! as Content)),
      ),
    ],
  );
});

/// Notifier interne qui ne fait rien pour l'instant.
class _RouterRefreshNotifier extends ChangeNotifier {
  /// Crée un [_RouterRefreshNotifier] qui n'écoute rien pour l'instant.
  _RouterRefreshNotifier(Ref ref);
}

/// Retourne la page de résultats correspondant aux paramètres de requête [queryParameters].
///
/// Le flair est prioritaire sur la recherche globale : sa présence signifie
/// que l'utilisateur a choisi une suggestion précise.
Widget _searchResultsScreenFor(Map<String, String> queryParameters) {
  final flair = queryParameters[searchFlairParam];
  if (flair != null) {
    return SearchResultsScreen(criteria: FlairSearchCriteria(flair));
  }
  final query = queryParameters[searchQueryParam];
  if (query != null) {
    return SearchResultsScreen(criteria: QuerySearchCriteria(query));
  }
  return const ErrorRoutePage(message: 'Missing search criteria');
}

/// Retourne la page de détail adaptée au type concret de [content].
Widget _contentDetailScreenFor(Content content) {
  if (content is TextContent) return TextContentDetailScreen(content: content);
  if (content is LinkContent) return LinkContentDetailScreen(content: content);
  if (content is MediaContent) return MediaContentDetailScreen(content: content);
  if (content is DrawingContent) return DrawingContentDetailScreen(content: content);
  return const ErrorRoutePage(message: 'Unknown content type');
}
