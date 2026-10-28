import 'package:bedbug/application/notifiers/content_author_notifier.dart';
import 'package:bedbug/application/screens/search_results/search_criteria.dart';
import 'package:bedbug/application/screens/search_results/search_results_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/style/social_network_x.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.dart';
import 'package:bedbug/application/widgets/signature/app_signature_bio.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur maximale du bedbug en tête de page.
///
/// Le bedbug prend toute la largeur disponible, mais une émote très courte
/// (`ʕ•ᴥ•ʔ`) deviendrait alors démesurément haute : on le plafonne.
const double _kMaxBedbugHeight = 140;

/// Page d'une signature : son bedbug en grand, son pseudo, ses réseaux, puis les contenus qu'elle a signés.
///
/// Ouverte depuis les suggestions de la recherche, ou depuis la page de détail
/// d'un contenu en touchant le pseudo ou le bedbug de son auteur. L'en-tête défile avec la
/// liste des contenus, pour que le grand bedbug ne prenne pas toute la place.
class SignatureScreen extends ConsumerWidget {
  /// Crée un [SignatureScreen].
  ///
  /// - [signatureId] : identifiant de la signature affichée.
  const SignatureScreen({super.key, required this.signatureId});

  /// Identifiant de la signature affichée.
  final String signatureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(signatureId));
    // Le temps de charger la signature, on présente la signature anonyme : la
    // mise en page reste stable au lieu de sauter une fois la signature chargée.
    final signature = contentAuthorNotifierWatcher.value ?? anonymousSignature;
    final colorArgb = signature.colorArgb;
    final ghostColor = colorArgb == null ? AppColors.primary : Color(colorArgb);
    final searchResultsNotifierWatcher = ref.watch(searchResultsNotifierProvider(SignatureSearchCriteria(signatureId)));

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(
                          onPressed: context.pop,
                          icon: const Icon(Icons.arrow_back, color: AppColors.onLight),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: _kMaxBedbugHeight),
                        child: FittedBox(
                          child: Padding(
                            // Laisse la place au tremblement du ghost, qui
                            // déborde légèrement du texte.
                            padding: const EdgeInsets.all(4),
                            child: AppSignatureAvatar(
                              avatarText: signature.avatarText,
                              ghostColor: ghostColor,
                              ghostSpeed: signature.ghostSpeed,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppPrefixedText(
                        prefix: AppPrefixes.signature,
                        text: signature.pseudo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onLight),
                      ),
                      if (signature.bio != null) ...[
                        const SizedBox(height: 8),
                        AppSignatureBio(bio: signature.bio!, font: signature.bioFont),
                      ],
                      if (signature.socialLinks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final network in signature.socialLinks.keys)
                              AppTag(label: network.displayName, color: ghostColor),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: searchResultsNotifierWatcher.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.homeGetContentsUnknown)),
            data: (state) {
              return ContentListView(
                contents: state.contents,
                emptyChild: Center(child: Text(state.failureMessage ?? l10n.signatureContentsEmpty)),
              );
            },
          ),
        ),
      ),
    );
  }
}
