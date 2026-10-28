import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:flutter/material.dart';

/// Correspondance entre une [TextFont] du domaine et la police embarquée dans l'application.
///
/// Le domaine ne connaît pas Flutter : c'est cette extension, côté
/// application, qui fait le lien avec les familles déclarées dans
/// `pubspec.yaml`.
extension TextFontX on TextFont {
  /// Famille de police déclarée dans `pubspec.yaml`, `null` pour garder celle du thème.
  String? get fontFamily {
    return switch (this) {
      TextFont.standard => null,
      TextFont.snowburstOne => 'SnowburstOne',
      TextFont.craftyGirls => 'CraftyGirls',
      TextFont.molle => 'Molle',
      TextFont.audiowide => 'Audiowide',
      TextFont.silkscreen => 'Silkscreen',
      TextFont.gugi => 'Gugi',
      TextFont.eater => 'Eater',
      TextFont.kablammo => 'Kablammo',
      TextFont.rockSalt => 'RockSalt',
      TextFont.lakkiReddy => 'LakkiReddy',
    };
  }

  /// Nom de la police tel qu'affiché dans le sélecteur, `null` pour [TextFont.standard].
  ///
  /// Ce sont des noms propres, identiques dans toutes les langues : ils ne
  /// passent donc pas par les fichiers de traduction. Seule la police par
  /// défaut, qui n'a pas de nom propre, est traduite.
  String? get displayName {
    return switch (this) {
      TextFont.standard => null,
      TextFont.snowburstOne => 'Snowburst One',
      TextFont.craftyGirls => 'Crafty Girls',
      TextFont.molle => 'Molle',
      TextFont.audiowide => 'Audiowide',
      TextFont.silkscreen => 'Silkscreen',
      TextFont.gugi => 'Gugi',
      TextFont.eater => 'Eater',
      TextFont.kablammo => 'Kablammo',
      TextFont.rockSalt => 'Rock Salt',
      TextFont.lakkiReddy => 'Lakki Reddy',
    };
  }

  /// Retourne [style] dans cette police.
  ///
  /// Les polices décoratives n'ont qu'une graisse et pas de variante
  /// italique : les simuler les déforme, d'où le retour au style normal.
  ///
  /// - [style] : style de base (taille, couleur…) à appliquer au texte.
  TextStyle apply(TextStyle style) {
    if (this == TextFont.standard) {
      return style;
    }
    return style.copyWith(fontFamily: fontFamily, fontStyle: FontStyle.normal, fontWeight: FontWeight.normal);
  }
}
