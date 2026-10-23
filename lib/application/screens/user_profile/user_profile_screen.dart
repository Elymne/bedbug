import 'package:bedbug/application/notifiers/content_author_notifier.dart';
import 'package:bedbug/application/screens/search_results/search_criteria.dart';
import 'package:bedbug/application/screens/search_results/search_results_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/style/social_network_x.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/application/widgets/user/app_user_avatar.dart';
import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur maximale de l'icône en tête de profil.
///
/// L'icône prend toute la largeur disponible, mais une émote très courte
/// (`ʕ•ᴥ•ʔ`) deviendrait alors démesurément haute : on la plafonne.
const double _kMaxAvatarHeight = 140;

/// Page profil d'un utilisateur : son icône en grand, son pseudo, ses réseaux, puis ses contenus.
///
/// Ouverte depuis les suggestions de la recherche. Les contenus sont
/// présentés dans des onglets (posts, commentaires) épinglés sous l'en-tête,
/// qui défile avec la liste.
class UserProfileScreen extends ConsumerWidget {
  /// Crée un [UserProfileScreen].
  ///
  /// - [userId] : identifiant de l'utilisateur affiché.
  const UserProfileScreen({super.key, required this.userId});

  /// Identifiant de l'utilisateur affiché.
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(userId));
    // Le temps de charger le profil, on présente le profil anonyme : la mise
    // en page reste stable au lieu de sauter une fois le profil chargé.
    final user = contentAuthorNotifierWatcher.value ?? anonymousUser;
    final colorArgb = user.colorArgb;
    final ghostColor = colorArgb == null ? AppColors.primary : Color(colorArgb);
    final searchResultsNotifierWatcher = ref.watch(searchResultsNotifierProvider(AuthorSearchCriteria(userId)));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: context.pop,
                          icon: const Icon(Icons.arrow_back, color: AppColors.onLight),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: _kMaxAvatarHeight),
                        child: FittedBox(
                          child: Padding(
                            // Laisse la place au tremblement du ghost, qui
                            // déborde légèrement du texte.
                            padding: const EdgeInsets.all(4),
                            child: AppUserAvatar(
                              avatarText: user.avatarText,
                              ghostColor: ghostColor,
                              ghostSpeed: user.ghostSpeed,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'u/${user.pseudo}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onLight),
                      ),
                      if (user.socialLinks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final network in user.socialLinks.keys)
                              AppTag(label: network.displayName, color: ghostColor),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 0,
                backgroundColor: AppColors.background,
                surfaceTintColor: AppColors.background,
                bottom: TabBar(
                  labelColor: AppColors.onLight,
                  unselectedLabelColor: AppColors.disabled,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: l10n.userProfilePostsTab),
                    Tab(text: l10n.userProfileCommentsTab),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              children: [
                searchResultsNotifierWatcher.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(child: Text(l10n.homeGetContentsUnknown)),
                  data: (state) => ContentListView(
                    contents: state.contents,
                    emptyChild: Center(child: Text(state.failureMessage ?? l10n.userProfilePostsEmpty)),
                  ),
                ),
                Center(
                  child: Text(l10n.userProfileCommentsSoon, style: const TextStyle(color: AppColors.disabled)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
