import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille de l'icône leading dans la carte.
const double _iconSize = 24;

/// Espacement horizontal entre les éléments de la carte.
const double _iconSpacing = 16;

/// Padding interne de la carte.
const double _cardPadding = 16;

/// Carte compacte réutilisable pour tous les types de contenu.
///
/// - Titre limité à 4 lignes.
/// - [preview] affiché sur 3 lignes uniquement si le titre tient sur 1 ligne.
/// - [trailing] optionnel affiché à droite (ex. image OG pour un lien).
class ContentCardWidget extends ConsumerWidget {
  /// Crée un [ContentCardWidget].
  ///
  /// - [icon] : icône représentant le type de contenu.
  /// - [title] : titre du contenu.
  /// - [preview] : texte de prévisualisation.
  /// - [trailing] : widget optionnel affiché à droite de la carte.
  const ContentCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.preview,
    this.trailing,
  });

  /// Icône représentant le type de contenu.
  final IconData icon;

  /// Titre du contenu.
  final String title;

  /// Texte de prévisualisation.
  final String preview;

  /// Widget optionnel affiché à droite (ex. thumbnail OG).
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _iconSpacing,
          children: [
            Icon(icon, size: _iconSize),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTitleSingleLine = _isSingleLine(
                    text: title,
                    style: titleStyle,
                    maxWidth: constraints.maxWidth,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle, maxLines: 4, overflow: TextOverflow.ellipsis),
                      if (isTitleSingleLine)
                        Text(preview, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  );
                },
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  /// Retourne `true` si [text] tient sur une seule ligne avec le [style] donné
  /// dans une largeur de [maxWidth].
  bool _isSingleLine({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return !painter.didExceedMaxLines;
  }
}
