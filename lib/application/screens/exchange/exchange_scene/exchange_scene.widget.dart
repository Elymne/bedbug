import 'dart:math' as math;

import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/application/widgets/signature/app_bedbug_frames.widget.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Durée du passage de la nuit au jour, ou du jour à la nuit.
const Duration _kTransitionDuration = Duration(milliseconds: 2400);

/// Durée du retour, plus rapide, vers l'état d'avant quand l'échange n'a pas pu changer d'état.
const Duration _kFailureReturnDuration = Duration(milliseconds: 500);

/// Durée de la montée de la colère quand l'échange n'a pas pu changer d'état.
const Duration _kAngerRiseDuration = Duration(milliseconds: 250);

/// Durée de l'apaisement du ciel rouge.
const Duration _kAngerFadeDuration = Duration(milliseconds: 600);

/// Temps pendant lequel le bedbug reste fâché avant de revenir à l'état d'avant.
const Duration _kAngerHoldDuration = Duration(milliseconds: 1200);

/// Durée d'une respiration (gonflement ou dégonflement) de la bordure des astres et du halo.
const Duration _kBreathDuration = Duration(seconds: 5);

/// Diamètre du soleil et de la lune.
const double _kCelestialSize = 64;

/// Épaisseur minimale de la bordure du soleil et de la lune, au creux de leur respiration.
const double _kCelestialMinBorder = 3;

/// Épaisseur gagnée par la bordure au plus fort de la respiration.
const double _kCelestialBorderGrowth = 5;

/// Hauteur du centre de l'astre levé, depuis le haut de la zone sûre.
const double _kCelestialTop = 110;

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

/// Bedbug endormi : il ronfle, bouche ouverte puis fermée, les `z` s'accumulant.
const List<String> _kSleepingFrames = ['(－_－) z  ', '(－o－) zZ ', '(－_－) zzZ'];

/// Bedbug réveillé : il bavarde avec les téléphones proches.
const List<String> _kAwakeFrames = ['(＾▽＾)', '(＾ｏ＾)'];

/// Bedbug fâché : il grogne parce que l'échange a planté.
const List<String> _kAngryFrames = ['(╬ Ò﹏Ó)', '(╬ Ò益Ó)'];

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
        final sky = Color.lerp(
          Color.lerp(AppColors.exchangeNightSky, AppColors.exchangeDaySky, day),
          AppColors.exchangeAngrySky,
          anger,
        )!;
        final foreground = Color.lerp(Color.lerp(AppColors.onDark, AppColors.onLight, day), AppColors.onDark, anger)!;
        final isAngry = anger > 0;
        final isAwake = day >= 0.5;

        return ColoredBox(
          color: sky,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Les deux astres sont opposés sur une roue qui tourne d'un demi-tour à chaque changement : la lune en
                // haut la nuit, le soleil en haut le jour.
                final wheelAngle = _isNightFalling ? math.pi * (2 - day) : math.pi * day;
                final pivot = Offset(constraints.maxWidth / 2, constraints.maxHeight * _kPivotDepth);
                final radius = pivot.dy - _kCelestialTop;
                final borderWidth = _kCelestialMinBorder + _kCelestialBorderGrowth * breath;

                return Stack(
                  children: [
                    _celestialBody(pivot, radius, wheelAngle, AppColors.moonGlow, borderWidth),
                    _celestialBody(pivot, radius, wheelAngle + math.pi, AppColors.sunGlow, borderWidth),
                    Center(
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
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onTap,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 16,
                          children: [
                            AppBedbugFrames(
                              frames: isAngry ? _kAngryFrames : (isAwake ? _kAwakeFrames : _kSleepingFrames),
                              speed: isAngry ? 1.5 : (isAwake ? 1 : 0.5),
                              style: TextStyle(
                                fontSize: _kBedbugFontSize,
                                fontWeight: FontWeight.w700,
                                color: foreground,
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
                    AppPageHeader(title: l10n.navExchangeLabel, onBack: context.pop, color: foreground),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Astre (soleil ou lune) placé sur la roue du ciel : un rond blanc dont la bordure respire.
  ///
  /// - [pivot] : centre de la roue, sous le bas de l'écran.
  /// - [radius] : rayon de la roue, du pivot à l'astre levé.
  /// - [angle] : angle de l'astre sur la roue, en radians, 0 tout en haut, dans le sens des aiguilles d'une montre.
  /// - [borderColor] : couleur de la bordure, celle de l'astre.
  /// - [borderWidth] : épaisseur actuelle de la bordure.
  Widget _celestialBody(Offset pivot, double radius, double angle, Color borderColor, double borderWidth) {
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
            border: Border.all(color: borderColor, width: borderWidth),
          ),
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
