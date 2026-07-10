import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/home/home_notifier.dart';
import 'package:bedbug/application/widgets/content_tile/content_widget.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Affiche la liste des contenus ou un message vide avec un bouton de reload.
///
/// - [contents] : liste des contenus à afficher.
/// - [controller] : contrôleur de scroll de la liste.
class ContentListView extends ConsumerWidget {
  /// Crée un [ContentListView].
  ///
  /// - [contents] : liste des contenus à afficher.
  /// - [controller] : contrôleur de scroll de la liste.
  const ContentListView({super.key, required this.contents, this.controller});

  /// Liste des contenus à afficher.
  final List<Content> contents;

  /// Contrôleur de scroll de la liste.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    if (contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(l10n.homeEmptyList),
            TextButton(
              onPressed: () {
                final notifier = ref.read(homeNotifierProvider.notifier);
                notifier.seedAndReload();
              },
              child: Text(l10n.homeSeedButton),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      itemCount: contents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => InkWell(
        onTap: () => context.push(contentDetailPath, extra: contents[index]),
        child: ContentWidget(content: contents[index]),
      ),
    );
  }
}
