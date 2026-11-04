import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_publishing/create_publishing.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/texts/app_loading_text.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page de chargement affichée par-dessus le formulaire de création pendant la publication.
///
/// Publier peut durer quelques secondes, le temps de lire l'aperçu d'un lien. Le formulaire reste intact derrière
/// cette page, pour être retrouvé tel quel en cas d'échec. Hors publication, ce widget n'affiche rien.
class CreatePublishing extends ConsumerWidget {
  /// Crée un [CreatePublishing].
  const CreatePublishing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createPublishingNotifierWatcher = ref.watch(createPublishingNotifierProvider);
    if (!createPublishingNotifierWatcher.isLoading) {
      return const SizedBox.shrink();
    }

    // Un Material plutôt qu'une simple couleur de fond : posée par-dessus le
    // Scaffold, la page n'hériterait sinon d'aucun style de texte (texte
    // souligné en jaune, couleur par défaut).
    return Material(
      color: AppColors.background,
      textStyle: const TextStyle(fontSize: 16, color: AppColors.onLight),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const CircularProgressIndicator(),
            // Le texte animé tient sur une ligne : réduit plutôt que de déborder
            // si la place manque (petit écran, police agrandie).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppLoadingText(text: AppLocalizations.of(context)!.createPublishingText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
