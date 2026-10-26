import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/avatar_picker/kaomoji_catalog.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de choix d'une icône de profil parmi le catalogue de kaomojis, classé par catégorie.
///
/// Un tap sur un kaomoji ferme la page et le renvoie à l'appelant via
/// `context.pop`. Le retour sans choix renvoie `null`.
///
/// Sert au choix de l'icône d'une signature comme au choix du bedbug d'une
/// réaction : seul le titre change.
class AvatarPickerScreen extends ConsumerWidget {
  /// Crée un [AvatarPickerScreen].
  ///
  /// - [title] : titre de la page, celui du choix d'icône de profil si `null`.
  const AvatarPickerScreen({super.key, this.title});

  /// Titre de la page. `null` pour celui du choix d'icône de profil.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: title ?? l10n.avatarPickerTitle, onBack: context.pop),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppValues.baseMargin, 0, AppValues.baseMargin, 32),
                children: [
                  for (final entry in kaomojiCatalog.entries) ...[
                    const SizedBox(height: 16),
                    Text(
                      _categoryTitle(l10n, entry.key),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onLight),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kaomoji in entry.value)
                          ActionChip(
                            label: Text(kaomoji, style: const TextStyle(fontSize: 16)),
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () => context.pop(kaomoji),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Titre traduit de la catégorie [category].
  String _categoryTitle(AppLocalizations l10n, KaomojiCategory category) {
    return switch (category) {
      KaomojiCategory.joy => l10n.avatarPickerCategoryJoy,
      KaomojiCategory.love => l10n.avatarPickerCategoryLove,
      KaomojiCategory.shy => l10n.avatarPickerCategoryShy,
      KaomojiCategory.sad => l10n.avatarPickerCategorySad,
      KaomojiCategory.angry => l10n.avatarPickerCategoryAngry,
      KaomojiCategory.scared => l10n.avatarPickerCategoryScared,
      KaomojiCategory.surprised => l10n.avatarPickerCategorySurprised,
      KaomojiCategory.meh => l10n.avatarPickerCategoryMeh,
      KaomojiCategory.greeting => l10n.avatarPickerCategoryGreeting,
      KaomojiCategory.hug => l10n.avatarPickerCategoryHug,
      KaomojiCategory.sleepy => l10n.avatarPickerCategorySleepy,
      KaomojiCategory.victory => l10n.avatarPickerCategoryVictory,
      KaomojiCategory.dance => l10n.avatarPickerCategoryDance,
      KaomojiCategory.tableFlip => l10n.avatarPickerCategoryTableFlip,
      KaomojiCategory.cat => l10n.avatarPickerCategoryCat,
      KaomojiCategory.bear => l10n.avatarPickerCategoryBear,
      KaomojiCategory.animal => l10n.avatarPickerCategoryAnimal,
    };
  }
}
