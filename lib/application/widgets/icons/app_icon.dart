import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Taille d'une icône quand ni le widget ni le thème d'icônes n'en imposent une.
const double _kDefaultSize = 24;

/// Affiche une icône de [AppIcons], à la place du widget `Icon` de Material.
///
/// Suit le thème d'icônes comme un `Icon` : un `IconButton`, une ligne de liste
/// ou un bouton lui donnent leur couleur et leur taille, désactivation comprise.
class AppIcon extends ConsumerWidget {
  /// Crée un [AppIcon].
  ///
  /// - [icon] : icône à afficher.
  /// - [color] : couleur de l'icône, `null` pour celle du thème d'icônes.
  /// - [size] : côté de l'icône, `null` pour celui du thème d'icônes.
  const AppIcon(this.icon, {super.key, this.color, this.size});

  /// Icône à afficher.
  final AppIcons icon;

  /// Couleur de l'icône, `null` pour celle du thème d'icônes.
  final Color? color;

  /// Côté de l'icône, `null` pour celui du thème d'icônes.
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconTheme = IconTheme.of(context);
    final effectiveColor = color ?? iconTheme.color ?? AppColors.onLight;
    final effectiveSize = size ?? iconTheme.size ?? _kDefaultSize;

    // Comme un `Icon` : forcée plus grande par son parent (le `suffixIcon` d'un champ
    // impose 48), l'icône garde sa taille et se centre au lieu de s'étirer.
    return SizedBox.square(
      dimension: effectiveSize,
      child: Center(
        child: SvgPicture.asset(
          icon.assetPath,
          width: effectiveSize,
          height: effectiveSize,
          matchTextDirection: icon.isDirectional,
          colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
