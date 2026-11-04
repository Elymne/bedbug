import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/settings/own_contents_section/own_contents_section.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/buttons/delete_content_button.widget.dart';
import 'package:bedbug/application/widgets/tags/app_tag.widget.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/core/extensions/datetime_x.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/content.extension.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Liste des posts publiés par l'utilisateur, anonymes compris, avec de quoi les supprimer.
///
/// Un tap sur un post ouvre sa page de détail ; la corbeille le supprime
/// après confirmation. Les posts anonymes sont signalés, puisqu'aucune
/// recherche par auteur ne les rattache à l'utilisateur.
class OwnContentsSection extends ConsumerWidget {
  /// Crée un [OwnContentsSection].
  const OwnContentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final ownContentsSectionNotifierWatcher = ref.watch(ownContentsSectionNotifierProvider);

    return ownContentsSectionNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(l10n.homeGetContentsUnknown),
      data: (state) {
        if (state.failureMessage != null) {
          return Text(state.failureMessage!);
        }
        if (state.contents.isEmpty) {
          return Text(l10n.settingsOwnContentsEmpty, style: const TextStyle(color: AppColors.disabled));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final content in state.contents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => context.push(contentDetailPath, extra: content),
                title: Text(content.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: AppPrefixedText(
                        prefix: flairPrefix,
                        text: '${content.flair}  •  ${content.createdAt.timeAgo}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.disabled),
                      ),
                    ),
                    if (content.signatureId == anonymousSignatureId)
                      AppTag(label: anonymousSignature.pseudo, colors: const [AppColors.onLighter]),
                  ],
                ),
                trailing: DeleteContentButton(contentId: content.id),
              ),
          ],
        );
      },
    );
  }
}
