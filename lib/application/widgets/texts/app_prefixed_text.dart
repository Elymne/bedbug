import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom précédé de son préfixe (`f/`, `s/`, voir `AppPrefixes`), le préfixe en couleur primaire.
///
/// Le préfixe signale d'un coup d'œil la nature du nom (flair, signature) :
/// il est coloré pour se détacher du reste du texte, qui garde [style].
class AppPrefixedText extends ConsumerWidget {
  /// Crée un [AppPrefixedText].
  ///
  /// - [prefix] : préfixe affiché en couleur primaire (ex. `f/`).
  /// - [text] : texte affiché après le préfixe.
  /// - [style] : style du texte entier ; seul le préfixe en change la couleur.
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

  /// Préfixe affiché en couleur primaire.
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
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: prefix,
            // En gras pour que le préfixe se repère d'un coup d'œil.
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
          TextSpan(text: text),
        ],
      ),
      style: style,
      overflow: overflow,
      maxLines: overflow == null ? null : 1,
      textAlign: textAlign,
    );
  }
}
