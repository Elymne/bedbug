import 'package:flutter/material.dart';

/// Palette de couleurs de référence de l'application.
class AppColors {
  AppColors._();

  /// Couleur primaire.
  static const Color primary = Color(0xFFFF7DA4);

  /// Couleur secondaire, un bleu ciel.
  static const Color secondary = Color(0xFF87CEEB);

  /// Couleur de fond de l'application, un beige très clair.
  static const Color background = Color(0xFFFFFAF5);

  /// Variante encore plus claire de [background], pour distinguer deux zones d'une même page.
  ///
  /// Ex. sur la page de détail : le contenu sur [background], ses réactions
  /// sur [backgroundLight].
  static const Color backgroundLight = Color(0xFFFFFDFA);

  /// Couleur de fond des cards, des inputs, checkbox et j'en passe.
  static const Color surface = Color(0xFFFFFFFF);

  /// Variante sombre de [surface], utilisée en fond des écrans nécessitant
  /// un meilleur contraste (ex. écran de recherche).
  static const Color surfaceDark = Color(0xFF414141);

  /// Couleur des éléments sur une surface claire.
  static const Color onLighter = Color(0xFF414141);

  /// Couleur des éléments sur une surface claire.
  static const Color onLight = Color(0xFF222222);

  /// Variante sombre de [onLight], utilisée comme second stop de gradient.
  static const Color onLightDeep = Color(0xFF0F0F0F);

  /// Couleur des éléments sur une surface sombre.
  static const Color onDark = Color(0xFFFFFFFF);

  /// Couleur des composants désactivés.
  static const Color disabled = Color(0xFFA0A0A0);

  /// Couleurs informatives INFO.
  static const Color info = Color(0xFF51C2FF);

  /// Couleurs informatives SUCCESS.
  ///
  /// Vert pastel, de même douceur que [primary], à associer à [onLight] pour le texte.
  static const Color success = Color(0xFF9BDDB1);

  /// Couleurs informatives FAILURE.
  static const Color failure = Color(0xFFFF4141);

  /// Voile posé derrière les popups : noir à 50 %, pour bien détacher la popup de la page.
  static const Color barrier = Color(0x80000000);

  /// Couleur des séparateurs et bordures discrètes.
  static const Color border = Color(0xFFE0E0E0);

  /// Couleur d'accentuation violette, utilisée entre autres pour les tags.
  static const Color purple = Color(0xFF9B59B6);

  /// Couleur d'accentuation orange, utilisée entre autres pour les tags.
  static const Color orange = Color(0xFFFF9D4D);

  /// Ciel de la page d'échange la nuit, quand l'échange est coupé : un bleu nuit.
  static const Color exchangeNightSky = Color(0xFF1B2440);

  /// Ciel de la page d'échange le jour, quand l'échange est actif : un jaune pâle et chaud.
  static const Color exchangeDaySky = Color(0xFFFFF3D6);

  /// Ciel de la page d'échange quand l'échange n'a pas pu démarrer : un rouge de colère.
  static const Color exchangeAngrySky = Color(0xFFD94848);

  /// Bordure de la lune, et halo qui respire derrière le bedbug endormi.
  static const Color moonGlow = Color(0xFF6FA8FF);

  /// Bordure du soleil, un jaune-orangé.
  static const Color sunGlow = Color(0xFFFFAA33);
}
