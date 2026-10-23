import 'package:bedbug/application/notifiers/delete_own_content_notifier.dart';
import 'package:bedbug/application/notifiers/own_contents_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/dialogs/delete_content_dialog.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/extensions/content_title_extension.dart';
import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:bedbug/shared/extensions/datetime_x.dart';
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
    final ownContentsNotifierWatcher = ref.watch(ownContentsNotifierProvider);
    final deleteOwnContentNotifierWatcher = ref.watch(deleteOwnContentNotifierProvider);

    return ownContentsNotifierWatcher.when(
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
                      child: Text(
                        '/${content.flair}  •  ${content.createdAt.timeAgo}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.disabled),
                      ),
                    ),
                    if (content.authorId == anonymousUserId)
                      AppTag(label: anonymousUser.pseudo, color: AppColors.onLighter),
                  ],
                ),
                trailing: IconButton(
                  onPressed: deleteOwnContentNotifierWatcher.isLoading ? null : () => _onDelete(context, ref, content),
                  tooltip: l10n.deleteContentButton,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.failure),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Demande confirmation puis supprime [content]. La liste se recharge d'elle-même en cas de succès.
  Future<void> _onDelete(BuildContext context, WidgetRef ref, Content content) async {
    final isConfirmed = await DeleteContentDialog.show(context);
    if (!isConfirmed || !context.mounted) {
      return;
    }

    final failureMessage = await ref.read(deleteOwnContentNotifierProvider.notifier).delete(content.id);
    if (!context.mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      return;
    }
    AppSnackbar.showSuccess(context, context.loc.deleteContentSuccess);
  }
}
