import 'package:bedbug/application/screens/home/home_notifier.dart';
import 'package:bedbug/application/widgets/content_tile/content_widget.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche la liste des contenus ou un message vide avec un bouton de reload.
///
/// - [contents] : liste des contenus à afficher.
class ContentList extends ConsumerWidget {
  /// Crée un [ContentList].
  ///
  /// - [contents] : liste des contenus à afficher.
  const ContentList({super.key, required this.contents});

  /// Liste des contenus à afficher.
  final List<Content> contents;

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
              onPressed: () => ref.read(homeNotifierProvider.notifier).seedAndReload(),
              child: Text(l10n.homeSeedButton),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contents.length,
      itemBuilder: (context, index) => ContentWidget(content: contents[index]),
    );
  }
}
