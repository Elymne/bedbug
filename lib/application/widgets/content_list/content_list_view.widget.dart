import 'package:bedbug/application/notifiers/trust_settings.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.config.dart';
import 'package:bedbug/application/widgets/content_list/content_view_tracker.widget.dart';
import 'package:bedbug/application/widgets/content_tile/content.widget.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.extension.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.config.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Affiche une liste de contenus cliquables, ou [emptyChild] si elle est vide.
///
/// Un tap sur un contenu ouvre sa page de détail. Partagée entre la home page
/// et la page de résultats de recherche, chacune fournissant son propre état
/// vide (bouton de génération sur la home, simple message côté recherche).
///
/// La liste est paginée : quand l'utilisateur approche de sa fin et que [hasMore] l'annonce, [onLoadMore] demande la
/// page suivante, et un loader termine la liste le temps qu'elle arrive. Après un échec, la fin de la liste affiche
/// [loadMoreFailureMessage] et un bouton pour réessayer, plutôt que de relancer la lecture en boucle.
class ContentListView extends ConsumerWidget {
  /// Crée un [ContentListView].
  ///
  /// - [contents] : liste des contenus à afficher, avec leur auteur et leur nombre de réactions.
  /// - [emptyChild] : widget affiché à la place de la liste quand [contents] est vide.
  /// - [controller] : contrôleur de scroll de la liste.
  /// - [onRefresh] : appelé quand l'utilisateur tire la liste vers le bas, `null` pour ne pas le proposer.
  /// - [unviewedContentIds] : identifiants des contenus à signaler comme nouveaux.
  /// - [onContentViewed] : appelé avec l'identifiant d'un contenu nouveau une fois vu, `null` pour ne pas les suivre.
  /// - [hasMore] : `true` s'il reste des contenus à charger après [contents].
  /// - [loadMoreFailureMessage] : message d'erreur du dernier chargement de la suite, `null` sans échec.
  /// - [onLoadMore] : appelé pour charger la suite de la liste, `null` pour une liste non paginée.
  const ContentListView({
    super.key,
    required this.contents,
    required this.emptyChild,
    this.controller,
    this.onRefresh,
    this.unviewedContentIds = const {},
    this.onContentViewed,
    this.hasMore = false,
    this.loadMoreFailureMessage,
    this.onLoadMore,
  });

  /// Liste des contenus à afficher, avec leur auteur et leur nombre de réactions.
  final List<ContentDetailed> contents;

  /// Widget affiché à la place de la liste quand [contents] est vide.
  final Widget emptyChild;

  /// Contrôleur de scroll de la liste.
  final ScrollController? controller;

  /// Appelé quand l'utilisateur tire la liste vers le bas, `null` pour ne pas le proposer.
  final Future<void> Function()? onRefresh;

  /// Identifiants des contenus à signaler comme nouveaux.
  final Set<String> unviewedContentIds;

  /// Appelé avec l'identifiant d'un contenu nouveau une fois vu, `null` pour ne pas les suivre.
  final void Function(String contentId)? onContentViewed;

  /// Indique s'il reste des contenus à charger après [contents].
  final bool hasMore;

  /// Message d'erreur du dernier chargement de la suite, `null` sans échec.
  final String? loadMoreFailureMessage;

  /// Appelé pour charger la suite de la liste, `null` pour une liste non paginée.
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustSettingsNotifierWatcher = ref.watch(trustSettingsNotifierProvider);
    // Tant que les réglages ne sont pas chargés, les réglages par défaut
    // s'appliquent : ce sont les plus prudents.
    final trustSettings = trustSettingsNotifierWatcher.value ?? defaultTrustSettings;
    // Les contenus de l'utilisateur restent toujours visibles : il sait ce
    // qu'il a publié, et doit pouvoir le retrouver.
    final visibleContents = [
      for (final detailed in contents)
        if (detailed.content.isOwned ||
            !TrustSettings.isContentHidden(
              trustSettings,
              mediaUrls: detailed.content.mediaUrls,
              linkUrls: detailed.content.linkUrls,
            ))
          detailed,
    ];
    final onLoadMore = this.onLoadMore;
    final hasFooter = onLoadMore != null && hasMore;
    final onRefresh = this.onRefresh;
    if (visibleContents.isEmpty && !hasFooter) {
      if (onRefresh == null) {
        return emptyChild;
      }
      // Un accueil vide doit rester rechargeable : c'est là qu'arrivent les premiers contenus reçus.
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: constraints.maxHeight, child: emptyChild),
            );
          },
        ),
      );
    }

    final loadMoreFailureMessage = this.loadMoreFailureMessage;
    final list = ListView.separated(
      controller: controller,
      // Une liste trop courte pour défiler doit pouvoir être tirée quand même.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      itemCount: visibleContents.length + (hasFooter ? 1 : 0),
      // Séparateurs en retrait des bords, comme ceux de la page de détail.
      separatorBuilder: (context, index) => const AppListSeparator(),
      itemBuilder: (context, index) {
        // Construire un des derniers éléments signifie que l'utilisateur approche de la fin : la suite est demandée
        // après l'image en cours, un notifier ne pouvant pas changer d'état pendant la construction d'un widget.
        // Après un échec, seul le bouton de la fin relance la lecture.
        if (hasFooter &&
            loadMoreFailureMessage == null &&
            index >= visibleContents.length - contentListLoadMoreThreshold) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
        }
        if (index == visibleContents.length) {
          if (loadMoreFailureMessage == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 8,
              children: [
                Text(
                  loadMoreFailureMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.disabled),
                ),
                TextButton(onPressed: onLoadMore, child: Text(context.loc.retry)),
              ],
            ),
          );
        }
        final detailed = visibleContents[index];
        final content = detailed.content;
        final isUnviewed = unviewedContentIds.contains(content.id);
        final tile = InkWell(
          onTap: () => context.push(contentDetailPath, extra: content),
          child: ContentWidget(detailed: detailed, isUnviewed: isUnviewed),
        );
        final onContentViewed = this.onContentViewed;
        if (!isUnviewed || onContentViewed == null) {
          return tile;
        }
        return ContentViewTracker(key: ValueKey(content.id), onViewed: () => onContentViewed(content.id), child: tile);
      },
    );
    if (onRefresh == null) {
      return list;
    }
    return RefreshIndicator(onRefresh: onRefresh, child: list);
  }
}
