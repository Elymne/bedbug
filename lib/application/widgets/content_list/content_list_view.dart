import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/widgets/content_tile/content_widget.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/extensions/content_urls_extension.dart';
import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/services/url_trust_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Affiche une liste de contenus cliquables, ou [emptyChild] si elle est vide.
///
/// Un tap sur un contenu ouvre sa page de détail. Partagée entre la home page
/// et la page de résultats de recherche, chacune fournissant son propre état
/// vide (bouton de génération sur la home, simple message côté recherche).
class ContentListView extends ConsumerWidget {
  /// Crée un [ContentListView].
  ///
  /// - [contents] : liste des contenus à afficher.
  /// - [emptyChild] : widget affiché à la place de la liste quand [contents] est vide.
  /// - [controller] : contrôleur de scroll de la liste.
  /// - [onRefresh] : appelé quand l'utilisateur tire la liste vers le bas, `null` pour ne pas le proposer.
  const ContentListView({super.key, required this.contents, required this.emptyChild, this.controller, this.onRefresh});

  /// Liste des contenus à afficher.
  final List<Content> contents;

  /// Widget affiché à la place de la liste quand [contents] est vide.
  final Widget emptyChild;

  /// Contrôleur de scroll de la liste.
  final ScrollController? controller;

  /// Appelé quand l'utilisateur tire la liste vers le bas, `null` pour ne pas le proposer.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustSettingsNotifierWatcher = ref.watch(trustSettingsNotifierProvider);
    // Tant que les réglages ne sont pas chargés, les réglages par défaut
    // s'appliquent : ce sont les plus prudents.
    final trustSettings = trustSettingsNotifierWatcher.value ?? defaultTrustSettings;
    // Les contenus de l'utilisateur restent toujours visibles : il sait ce
    // qu'il a publié, et doit pouvoir le retrouver.
    final visibleContents = [
      for (final content in contents)
        if (content.isOwned ||
            !ref
                .read(urlTrustServiceProvider)
                .isContentHidden(trustSettings, mediaUrls: content.mediaUrls, linkUrls: content.linkUrls))
          content,
    ];
    final onRefresh = this.onRefresh;
    if (visibleContents.isEmpty) {
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

    final list = ListView.separated(
      controller: controller,
      // Une liste trop courte pour défiler doit pouvoir être tirée quand même.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      itemCount: visibleContents.length,
      // Séparateurs en retrait des bords, comme ceux de la page de détail.
      separatorBuilder: (context, index) => const AppListSeparator(),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => context.push(contentDetailPath, extra: visibleContents[index]),
          child: ContentWidget(content: visibleContents[index]),
        );
      },
    );
    if (onRefresh == null) {
      return list;
    }
    return RefreshIndicator(onRefresh: onRefresh, child: list);
  }
}
