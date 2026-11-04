import 'dart:math' as math;

import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_system_ui.config.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.widget.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/application/widgets/signature/app_bedbug_frames.widget.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Durée du passage de la nuit au jour, ou du jour à la nuit.
const Duration _kTransitionDuration = Duration(milliseconds: 1400);

/// Durée du retour, plus rapide, vers l'état d'avant quand l'échange n'a pas pu changer d'état.
const Duration _kFailureReturnDuration = Duration(milliseconds: 500);

/// Durée de la montée de la colère quand l'échange n'a pas pu changer d'état.
const Duration _kAngerRiseDuration = Duration(milliseconds: 250);

/// Durée de l'apaisement du ciel rouge.
const Duration _kAngerFadeDuration = Duration(milliseconds: 600);

/// Temps pendant lequel le bedbug reste fâché avant de revenir à l'état d'avant.
const Duration _kAngerHoldDuration = Duration(milliseconds: 1200);

/// Durée d'une respiration (gonflement ou dégonflement) du halo des astres et de celui du bedbug.
const Duration _kBreathDuration = Duration(seconds: 5);

/// Diamètre du soleil et de la lune.
const double _kCelestialSize = 180;

/// Flou du halo lumineux autour du soleil et de la lune, au creux de leur respiration.
const double _kGlowMinBlur = 18;

/// Flou gagné par le halo au plus fort de la respiration.
const double _kGlowBlurGrowth = 14;

/// Étalement du halo autour de l'astre, au creux de sa respiration.
const double _kGlowMinSpread = 2;

/// Étalement gagné par le halo au plus fort de la respiration.
const double _kGlowSpreadGrowth = 4;

/// Opacité du halo lumineux autour du soleil et de la lune.
const double _kGlowOpacity = 0.75;

/// Cratères de la lune : position de leur centre et rayon, en fraction du diamètre de la lune.
const List<({double x, double y, double radius})> _kMoonCraters = [
  (x: 0.32, y: 0.30, radius: 0.09),
  (x: 0.62, y: 0.24, radius: 0.05),
  (x: 0.60, y: 0.58, radius: 0.12),
  (x: 0.30, y: 0.64, radius: 0.06),
  (x: 0.46, y: 0.44, radius: 0.035),
  (x: 0.74, y: 0.42, radius: 0.04),
];

/// Hauteur de l'en-tête de la page (bouton retour et titre), sous la barre d'état.
///
/// L'astre levé se place dessous : blanc, il rendrait illisibles le titre et la flèche, blancs eux aussi la nuit.
const double _kHeaderHeight = 72;

/// Espace entre le bas de l'en-tête et le haut de l'astre levé.
const double _kCelestialGap = 16;

/// Position verticale du bedbug, de -1 (haut) à 1 (bas) : un peu sous le milieu, pour laisser la place à l'astre.
const double _kBedbugAlignmentY = 0.3;

/// Position verticale du pivot de la course des astres, en fraction de la hauteur : sous le bas de l'écran, pour
/// qu'un astre couché soit hors de la vue.
const double _kPivotDepth = 1.15;

/// Diamètre du halo qui respire derrière le bedbug endormi.
const double _kHaloSize = 260;

/// Opacité du halo au creux de sa respiration.
const double _kHaloMinOpacity = 0.10;

/// Opacité gagnée par le halo au plus fort de sa respiration.
const double _kHaloOpacityGrowth = 0.08;

/// Taille du bedbug au centre de la page.
const double _kBedbugFontSize = 52;

// Les frames d'un même bedbug n'utilisent que des caractères pleine chasse pour la bouche (＿, ｏ, －, 益, 皿) : ils ont
// tous la même largeur, et la tête ne bouge pas d'une frame à l'autre.

/// Bedbug endormi : il ronfle, la bouche s'ouvre au milieu de chaque ronflement.
const List<String> _kSleepingFrames = ['(－＿－)', '(－ｏ－)', '(－＿－)'];

/// Ronflement du bedbug endormi, à côté de sa tête : les `z` s'accumulent au rythme de sa bouche.
const List<String> _kSnoreFrames = ['z', 'zZ', 'zzZ'];

/// Bedbug réveillé : il danse, les bras levés d'un côté puis de l'autre, en chantant.
///
/// Les bras sont des caractères de dessin de cadre (└ ┐ ┌ ┘), tous de même largeur : seuls les bras bougent.
const List<String> _kAwakeFrames = ['└(＾ｏ＾)┐', '┌(＾－＾)┘'];

/// Musique du bedbug qui danse, à côté de sa tête, à la place des `z` de la nuit.
const List<String> _kMusicFrames = ['♪', '♪♫', '♫'];

/// Bedbug fâché : il grogne parce que l'échange a planté.
const List<String> _kAngryFrames = ['(╬ Ò益Ó)', '(╬ Ò皿Ó)'];

/// Vitesse de l'animation du bedbug endormi et de son ronflement : lente, comme une respiration.
const double _kSleepingSpeed = 0.5;

/// Taille des `z` du ronflement.
const double _kSnoreFontSize = 24;

/// Largeur réservée aux `z` du ronflement, à droite de la tête.
const double _kSnoreWidth = 64;

/// Hauteur dont les `z` dépassent au-dessus de la tête.
const double _kSnoreRise = 16;

/// Scène de la page d'échange : un bedbug qui dort la nuit, quand l'échange est coupé, et qui veille le jour, quand
/// il est actif. Un tap sur le bedbug le réveille ou l'endort, et lance ou coupe l'échange.
///
/// Une case à cocher disait la même chose, mais sans rien raconter : ici, l'état de l'échange se lit d'un coup d'œil
/// (nuit ou jour). Le passage de l'un à l'autre fait tourner le ciel : la lune se couche pendant que le soleil se
/// lève, et le fond change de couleur progressivement. Si l'échange ne peut pas changer d'état, le bedbug se fâche,
/// le ciel rougit, une erreur s'affiche, puis le ciel revient vite à l'état d'avant.
///
/// Toute l'animation est un état d'interface propre à ce widget, tenu par ses contrôleurs : le notifier de l'échange
/// n'est que lu au tap, et écouté pour suivre un arrêt venu d'ailleurs (la notification).
class ExchangeScene extends ConsumerStatefulWidget {
  /// Crée un [ExchangeScene].
  const ExchangeScene({super.key});

  @override
  ConsumerState<ExchangeScene> createState() => _State();
}

class _State extends ConsumerState<ExchangeScene> with TickerProviderStateMixin {
  /// Avancement du jour : 0 la nuit, 1 le jour. Part de l'état de l'échange à l'ouverture de la page.
  late final _dayController = AnimationController(
    vsync: this,
    duration: _kTransitionDuration,
    value: (ref.read(passiveExchangeNotifierProvider).value ?? false) ? 1 : 0,
  );

  /// Colère du bedbug : 0 au calme, 1 fâché, le ciel rouge.
  late final _angerController = AnimationController(vsync: this, duration: _kAngerRiseDuration);

  /// Respiration lente de la bordure des astres et du halo, en aller-retour permanent.
  late final _breathController = AnimationController(vsync: this, duration: _kBreathDuration)..repeat(reverse: true);

  /// Indique si le ciel tourne pour faire tomber la nuit : la roue continue alors sa course (le soleil se couche à
  /// droite, la lune se lève à gauche) au lieu de rebrousser chemin.
  bool _isNightFalling = false;

  /// Indique si un changement d'état lancé par un tap est en cours, tant que son animation lui appartient.
  bool _isToggling = false;

  @override
  void dispose() {
    _dayController.dispose();
    _angerController.dispose();
    _breathController.dispose();
    // La scène a rendu la barre d'état transparente pour que son ciel passe dessous : rétablir celle du reste de l'app.
    SystemChrome.setSystemUIOverlayStyle(appSystemUiOverlayStyle);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;

    // L'échange peut s'arrêter sans passer par cette page (depuis la notification) : le ciel suit.
    ref.listen(passiveExchangeNotifierProvider, (previous, next) {
      if (next.isLoading) {
        return;
      }
      if (_isToggling) {
        return;
      }
      _animateTo(isDay: next.value ?? false, duration: _kTransitionDuration);
    });

    return AnimatedBuilder(
      animation: Listenable.merge([_dayController, _angerController, _breathController]),
      builder: (context, child) {
        final day = Curves.easeInOut.transform(_dayController.value);
        final anger = _angerController.value;
        final breath = Curves.easeInOut.transform(_breathController.value);
        // La nuit, le ciel se dégrade du noir en haut au bleu nuit en bas ; le jour et la colère sont unis. Chaque bout
        // du dégradé change de couleur séparément, pour une transition fluide.
        final skyTop = Color.lerp(
          Color.lerp(AppColors.exchangeNightSkyTop, AppColors.exchangeDaySky, day),
          AppColors.exchangeAngrySky,
          anger,
        )!;
        final skyBottom = Color.lerp(
          Color.lerp(AppColors.exchangeNightSky, AppColors.exchangeDaySky, day),
          AppColors.exchangeAngrySky,
          anger,
        )!;
        final foreground = Color.lerp(Color.lerp(AppColors.onDark, AppColors.onLight, day), AppColors.onDark, anger)!;
        final isAngry = anger > 0;
        final isAwake = day >= 0.5;
        final isAsleep = !isAngry && !isAwake;
        final isSkyDark = isAngry || !isAwake;

        // Le ciel passe sous la barre d'état, rendue transparente ; ses icônes restent lisibles sur le ciel du moment.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: AppColors.transparent,
            statusBarIconBrightness: isSkyDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isSkyDark ? Brightness.dark : Brightness.light,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [skyTop, skyBottom],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Les deux astres sont opposés sur une roue qui tourne d'un demi-tour à chaque changement : la lune en
                // haut la nuit, le soleil en haut le jour.
                // Courbe plus marquée que celle du ciel : l'astre part doucement, file au milieu de sa course et freine en
                // arrivant, comme s'il se posait.
                final wheel = Curves.easeInOutCubic.transform(_dayController.value);
                final wheelAngle = _isNightFalling ? math.pi * (2 - wheel) : math.pi * wheel;
                final pivot = Offset(constraints.maxWidth / 2, constraints.maxHeight * _kPivotDepth);
                final celestialTop =
                    MediaQuery.paddingOf(context).top + _kHeaderHeight + _kCelestialGap + _kCelestialSize / 2;
                final radius = pivot.dy - celestialTop;
                final glowBlur = _kGlowMinBlur + _kGlowBlurGrowth * breath;
                final glowSpread = _kGlowMinSpread + _kGlowSpreadGrowth * breath;
                // Ghost du bedbug : bleu lune la nuit, orangé soleil le jour, sombre sur le ciel rouge de la colère.
                final ghostColor = Color.lerp(
                  Color.lerp(AppColors.moonGlow, AppColors.sunGlow, day),
                  AppColors.onLightDeep,
                  anger,
                )!;
                final bedbugStyle = TextStyle(
                  fontSize: _kBedbugFontSize,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                );

                return Stack(
                  children: [
                    _celestialBody(
                      pivot,
                      radius,
                      wheelAngle,
                      AppColors.moonGlow,
                      glowBlur,
                      glowSpread,
                      hasCraters: true,
                    ),
                    _celestialBody(pivot, radius, wheelAngle + math.pi, AppColors.sunGlow, glowBlur, glowSpread),
                    Align(
                      alignment: const Alignment(0, _kBedbugAlignmentY),
                      child: IgnorePointer(
                        child: Container(
                          width: _kHaloSize,
                          height: _kHaloSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.moonGlow.withValues(
                                  alpha: (1 - day) * (_kHaloMinOpacity + _kHaloOpacityGrowth * breath),
                                ),
                                AppColors.moonGlow.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, _kBedbugAlignmentY),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onTap,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 16,
                          children: [
                            // Les `z` sont à côté de la tête, hors de sa mise en page : la tête reste centrée et
                            // immobile pendant qu'ils s'accumulent.
                            AppGhostEffect(
                              isAnimating: true,
                              speed: isAngry ? 2 : (isAwake ? 1 : _kSleepingSpeed),
                              // L'amplitude suit la taille du bedbug, comme pour l'icône d'une signature.
                              intensity: _kBedbugFontSize / 32,
                              ghostColor: ghostColor,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AppBedbugFrames(
                                    frames: isAngry ? _kAngryFrames : (isAwake ? _kAwakeFrames : _kSleepingFrames),
                                    speed: isAngry ? 1.5 : (isAwake ? 1 : _kSleepingSpeed),
                                    style: bedbugStyle,
                                  ),
                                  if (!isAngry)
                                    Positioned(
                                      top: -_kSnoreRise,
                                      right: -_kSnoreWidth,
                                      width: _kSnoreWidth,
                                      child: AppBedbugFrames(
                                        frames: isAsleep ? _kSnoreFrames : _kMusicFrames,
                                        speed: isAsleep ? _kSleepingSpeed : 1,
                                        alignment: AlignmentDirectional.centerStart,
                                        style: bedbugStyle.copyWith(fontSize: _kSnoreFontSize),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              isAwake ? l10n.exchangeAwakeHint : l10n.exchangeSleepingHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: foreground.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: AppPageHeader(title: l10n.navExchangeLabel, onBack: context.pop, color: foreground),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Astre (soleil ou lune) placé sur la roue du ciel : un rond blanc entouré d'un halo lumineux qui respire.
  ///
  /// - [pivot] : centre de la roue, sous le bas de l'écran.
  /// - [radius] : rayon de la roue, du pivot à l'astre levé.
  /// - [angle] : angle de l'astre sur la roue, en radians, 0 tout en haut, dans le sens des aiguilles d'une montre.
  /// - [glowColor] : couleur du halo, celle de l'astre.
  /// - [glowBlur] : flou actuel du halo.
  /// - [glowSpread] : étalement actuel du halo autour de l'astre.
  /// - [hasCraters] : `true` pour parsemer l'astre de cratères gris clair, ce qui en fait la lune.
  Widget _celestialBody(
    Offset pivot,
    double radius,
    double angle,
    Color glowColor,
    double glowBlur,
    double glowSpread, {
    bool hasCraters = false,
  }) {
    final center = Offset(pivot.dx + radius * math.sin(angle), pivot.dy - radius * math.cos(angle));
    return Positioned(
      left: center.dx - _kCelestialSize / 2,
      top: center.dy - _kCelestialSize / 2,
      child: IgnorePointer(
        child: Container(
          width: _kCelestialSize,
          height: _kCelestialSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            // Une ombre floue de la couleur de l'astre plutôt qu'une bordure : l'astre rayonne au lieu d'être cerclé.
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: _kGlowOpacity),
                blurRadius: glowBlur,
                spreadRadius: glowSpread,
              ),
            ],
          ),
          child: hasCraters
              ? Stack(
                  children: [
                    for (final crater in _kMoonCraters)
                      Positioned(
                        left: (crater.x - crater.radius) * _kCelestialSize,
                        top: (crater.y - crater.radius) * _kCelestialSize,
                        child: Container(
                          width: crater.radius * 2 * _kCelestialSize,
                          height: crater.radius * 2 * _kCelestialSize,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.moonCrater),
                        ),
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  /// Fait tourner le ciel vers le jour ou vers la nuit.
  ///
  /// Vers la nuit, la roue poursuit sa course plutôt que de revenir sur ses pas : le soleil se couche à droite et la
  /// lune se lève à gauche, comme le jour s'est levé.
  ///
  /// - [isDay] : `true` pour aller vers le jour.
  /// - [duration] : durée d'un passage complet.
  void _animateTo({required bool isDay, required Duration duration}) {
    if (isDay) {
      _isNightFalling = false;
      _dayController.animateTo(1, duration: duration);
      return;
    }
    _isNightFalling = true;
    _dayController.animateBack(0, duration: duration);
  }

  /// Réveille ou endort le bedbug, et lance ou coupe l'échange en conséquence.
  ///
  /// Le ciel commence à tourner dès le tap, sans attendre que l'échange ait démarré : la page répond tout de suite.
  /// Un tap pendant un changement en cours est ignoré.
  Future<void> _onTap() async {
    final exchange = ref.read(passiveExchangeNotifierProvider);
    if (_isToggling || exchange.isLoading) {
      return;
    }
    final isEnabling = !(exchange.value ?? false);
    _isToggling = true;
    _animateTo(isDay: isEnabling, duration: _kTransitionDuration);

    final failureMessage = await ref.read(passiveExchangeNotifierProvider.notifier).setEnabled(isEnabled: isEnabling);
    if (!mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      await _showAnger(isDay: !isEnabling);
    }
    _isToggling = false;
  }

  /// Fâche le bedbug, puis ramène vite le ciel à l'état d'avant le tap.
  ///
  /// Le ciel rebrousse chemin le long de la même course : l'astre qui se levait se recouche du côté d'où il venait.
  ///
  /// - [isDay] : `true` si l'état d'avant était le jour.
  Future<void> _showAnger({required bool isDay}) async {
    _dayController.stop();
    await _angerController.animateTo(1, duration: _kAngerRiseDuration);
    await Future<void>.delayed(_kAngerHoldDuration);
    if (!mounted) {
      return;
    }
    _angerController.animateBack(0, duration: _kAngerFadeDuration);
    if (isDay) {
      await _dayController.animateTo(1, duration: _kFailureReturnDuration);
      return;
    }
    await _dayController.animateTo(0, duration: _kFailureReturnDuration);
  }
}
