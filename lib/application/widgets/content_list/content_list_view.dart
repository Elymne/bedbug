import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/content_tile/content_widget.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
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
  const ContentListView({super.key, required this.contents, required this.emptyChild, this.controller});

  /// Liste des contenus à afficher.
  final List<Content> contents;

  /// Widget affiché à la place de la liste quand [contents] est vide.
  final Widget emptyChild;

  /// Contrôleur de scroll de la liste.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contents.isEmpty) {
      return emptyChild;
    }

    return ListView.separated(
      controller: controller,
      itemCount: contents.length,
      // Séparateurs en retrait des bords, comme ceux de la page de détail.
      separatorBuilder: (context, index) {
        return const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: AppColors.border);
      },
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => context.push(contentDetailPath, extra: contents[index]),
          child: ContentWidget(content: contents[index]),
        );
      },
    );
  }
}
