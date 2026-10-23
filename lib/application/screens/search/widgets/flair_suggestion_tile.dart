import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:bedbug/features/content/domain/object_values/flair_suggestion.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ligne d'autocomplétion présentant un flair existant et son nombre de contenus.
///
/// Conçue pour le fond sombre de l'écran de recherche.
class FlairSuggestionTile extends ConsumerWidget {
  /// Crée un [FlairSuggestionTile].
  ///
  /// - [suggestion] : flair proposé et son nombre de contenus.
  /// - [onTap] : callback déclenché quand l'utilisateur choisit ce flair.
  const FlairSuggestionTile({super.key, required this.suggestion, required this.onTap});

  /// Flair proposé et son nombre de contenus.
  final FlairSuggestion suggestion;

  /// Callback déclenché quand l'utilisateur choisit ce flair.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary,
        child: Text(
          AppPrefixes.flair,
          style: TextStyle(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      title: AppPrefixedText(
        prefix: AppPrefixes.flair,
        text: suggestion.flair,
        style: const TextStyle(color: AppColors.onDark, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        context.loc.searchFlairSuggestionCount(suggestion.contentCount),
        style: const TextStyle(color: AppColors.disabled, fontSize: 13),
      ),
    );
  }
}
