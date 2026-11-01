import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/fields/app_pulse_input_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Durée d'un mouvement du halo, dans un sens : lente, pour rester discrète.
const Duration _kPulseDuration = Duration(milliseconds: 1200);

/// Signale le champ actif de [child] par un halo qui grossit et rétrécit lentement derrière sa bordure.
///
/// À poser autour de tout champ de formulaire. Une bordure de champ ne sait pas
/// s'animer seule : ce widget porte donc l'animation, la confie aux bordures
/// de focus du thème, et redessine le champ à chaque étape. L'animation ne
/// tourne que pendant le focus.
class AppFieldFocusPulse extends ConsumerStatefulWidget {
  /// Crée un [AppFieldFocusPulse].
  ///
  /// - [child] : champ de formulaire à animer.
  const AppFieldFocusPulse({super.key, required this.child});

  /// Champ de formulaire à animer.
  final Widget child;

  @override
  ConsumerState<AppFieldFocusPulse> createState() => _State();
}

class _State extends ConsumerState<AppFieldFocusPulse> with SingleTickerProviderStateMixin {
  /// Progression brute du halo, en aller-retour pendant le focus.
  late final AnimationController _controller = AnimationController(duration: _kPulseDuration, vsync: this);

  /// Progression du halo, adoucie aux deux extrémités du mouvement.
  late final CurvedAnimation _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _onFocusChange,
      // Isole le dessin : seul ce champ est redessiné à chaque frame.
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PulseRepaintPainter(_pulse),
          child: Theme(
            data: theme.copyWith(
              inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                focusedBorder: AppPulseInputBorder(
                  pulse: _pulse,
                  haloColor: AppColors.primary,
                  borderSide: const BorderSide(color: AppColors.onLight),
                  borderRadius: BorderRadius.circular(AppValues.fieldRadius),
                ),
                focusedErrorBorder: AppPulseInputBorder(
                  pulse: _pulse,
                  haloColor: AppColors.failure,
                  borderSide: const BorderSide(color: AppColors.failure),
                  borderRadius: BorderRadius.circular(AppValues.fieldRadius),
                ),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  /// Lance le halo quand le champ prend le focus, et le ramène au repos quand il le perd.
  ///
  /// - [hasFocus] : `true` si le champ vient de prendre le focus.
  void _onFocusChange(bool hasFocus) {
    if (hasFocus) {
      _controller.repeat(reverse: true);
      return;
    }
    _controller
      ..stop()
      ..value = 0;
  }
}

/// Peintre vide dont le seul rôle est de provoquer un nouveau dessin à chaque étape du halo.
///
/// La bordure d'un champ n'écoute pas [AppPulseInputBorder.pulse]. Marquer ce
/// peintre comme à redessiner entraîne le dessin de ses descendants, donc
/// celui de la bordure.
class _PulseRepaintPainter extends CustomPainter {
  /// Crée un [_PulseRepaintPainter].
  ///
  /// - [pulse] : animation qui déclenche les nouveaux dessins.
  _PulseRepaintPainter(Animation<double> pulse) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_PulseRepaintPainter oldDelegate) {
    return false;
  }
}
