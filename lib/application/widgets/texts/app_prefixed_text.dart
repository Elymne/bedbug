import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vitesse de l'effet ghost du préfixe, plus lente que la normale.
///
/// Le préfixe est répété sur chaque tuile et chaque suggestion : un
/// tremblement discret le distingue sans fatiguer la lecture.
const double _kPrefixGhostSpeed = 0.5;

/// Amplitude de l'effet ghost du préfixe, en pixels, réduite pour rester lisible à petite taille.
const double _kPrefixGhostIntensity = 0.5;

/// Nom précédé de son préfixe (`f/`, `s/`, voir `AppPrefixes`), le préfixe en gras avec un léger effet ghost.
///
/// Le préfixe signale d'un coup d'œil la nature du nom (flair, signature).
/// Il garde la couleur du texte, plus lisible que la couleur primaire sur
/// fond clair, et c'est son effet ghost en couleur primaire qui le fait
/// ressortir.
class AppPrefixedText extends ConsumerWidget {
  /// Crée un [AppPrefixedText].
  ///
  /// - [prefix] : préfixe affiché en gras avec l'effet ghost (ex. `f/`).
  /// - [text] : texte affiché après le préfixe.
  /// - [style] : style du texte entier, préfixe compris ; le préfixe passe seulement en gras.
  /// - [overflow] : gestion du débordement, sur une seule ligne si renseigné.
  /// - [textAlign] : alignement du texte.
  const AppPrefixedText({
    super.key,
    required this.prefix,
    required this.text,
    this.style,
    this.overflow,
    this.textAlign,
  });

  /// Préfixe affiché en gras avec l'effet ghost.
  final String prefix;

  /// Texte affiché après le préfixe.
  final String text;

  /// Style du texte entier.
  final TextStyle? style;

  /// Gestion du débordement.
  final TextOverflow? overflow;

  /// Alignement du texte.
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sans préfixe, rien à animer : une animation à vide tournerait pour rien.
    if (prefix.isEmpty) {
      return Text(text, style: style, overflow: overflow, maxLines: overflow == null ? null : 1, textAlign: textAlign);
    }

    // Un `WidgetSpan` n'hérite pas du style du `Text.rich` : on lui transmet
    // explicitement, en gras pour que le préfixe se repère d'un coup d'œil.
    final prefixStyle = DefaultTextStyle.of(context).style
        .merge(style)
        .merge(const TextStyle(fontWeight: FontWeight.w800));

    // Le préfixe, rendu à part, serait lu séparément du nom : le libellé
    // rassemble les deux pour les lecteurs d'écran.
    return Semantics(
      label: '$prefix$text',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: AppGhostEffect(
                isAnimating: true,
                speed: _kPrefixGhostSpeed,
                intensity: _kPrefixGhostIntensity,
                ghostColor: AppColors.primary,
                // Le `Text.rich` met déjà à l'échelle ses `WidgetSpan` : sans
                // `noScaling`, le préfixe serait agrandi deux fois.
                child: Text(prefix, style: prefixStyle, textScaler: TextScaler.noScaling),
              ),
            ),
            TextSpan(text: text),
          ],
        ),
        style: style,
        overflow: overflow,
        maxLines: overflow == null ? null : 1,
        textAlign: textAlign,
      ),
    );
  }
}
