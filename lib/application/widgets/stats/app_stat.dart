import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistique compacte : une icône suivie d'un nombre, tous deux dans la même couleur.
///
/// Remplace un tag quand seul un chiffre compte (rebonds, réactions) : plus
/// léger visuellement, il laisse la place aux vrais tags du contenu.
/// [semanticsLabel] est lu par les lecteurs d'écran à la place de l'icône et
/// du nombre, qui seuls ne veulent rien dire.
class AppStat extends ConsumerWidget {
  /// Crée une [AppStat].
  ///
  /// - [icon] : icône de la statistique, déjà dans la bonne couleur.
  /// - [label] : nombre affiché (ex. `+12`).
  /// - [color] : couleur du nombre, celle de l'icône.
  /// - [semanticsLabel] : libellé complet lu par les lecteurs d'écran (ex. « 12 rebonds »).
  const AppStat({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.semanticsLabel,
  });

  /// Icône de la statistique.
  final Widget icon;

  /// Nombre affiché.
  final String label;

  /// Couleur du nombre.
  final Color color;

  /// Libellé complet lu par les lecteurs d'écran.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          icon,
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
