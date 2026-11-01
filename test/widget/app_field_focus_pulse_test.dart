import 'package:bedbug/application/widgets/fields/app_field_focus_pulse.dart';
import 'package:bedbug/application/widgets/fields/app_pulse_input_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Bordure comptant ses dessins, pour observer ce que le champ redessine réellement.
class _CountingInputBorder extends OutlineInputBorder {
  /// Crée un [_CountingInputBorder].
  ///
  /// - [onPaint] : appelé à chaque dessin.
  const _CountingInputBorder(this.onPaint);

  /// Appelé à chaque dessin.
  final VoidCallback onPaint;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    onPaint();
    super.paint(canvas, rect);
  }
}

void main() {
  testWidgets('redessine la bordure pendant le focus, et plus du tout après', (tester) async {
    var paintCount = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final border = _CountingInputBorder(() => paintCount++);

    await pumpApp(
      tester,
      Scaffold(
        body: AppFieldFocusPulse(
          child: TextField(
            focusNode: focusNode,
            decoration: InputDecoration(enabledBorder: border, focusedBorder: border),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    paintCount = 0;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(paintCount, 2, reason: "chaque frame de l'animation doit repasser par la bordure");

    focusNode.unfocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    paintCount = 0;
    await tester.pump(const Duration(milliseconds: 16));
    expect(paintCount, 0, reason: 'le halo ne doit plus rien animer une fois le focus perdu');
  });

  test("garde son halo à l'issue de la transition et après un copyWith", () {
    const border = AppPulseInputBorder(pulse: kAlwaysDismissedAnimation, haloColor: Color(0xFF000000));

    expect(ShapeBorder.lerp(const OutlineInputBorder(), border, 1), same(border));
    expect(border.copyWith(gapPadding: 2), isA<AppPulseInputBorder>());
  });

  testWidgets('dessine un halo qui change de largeur et reste hors de la zone de saisie', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: AppFieldFocusPulse(child: TextField(focusNode: focusNode)),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    // Laisse se terminer la transition de bordure de Flutter, puis une partie du mouvement du halo.
    await tester.pump(const Duration(milliseconds: 600));

    final decorator = tester.renderObject(find.byType(InputDecorator));
    final thin = _StrokeWidthCollector();
    expect(decorator, paints..everything(thin.collect));

    await tester.pump(const Duration(milliseconds: 500));
    final wide = _StrokeWidthCollector();
    expect(decorator, paints..everything(wide.collect));

    expect(thin.widths, isNotEmpty);
    expect(wide.widths.first, greaterThan(thin.widths.first));
  });
}

/// Relève l'épaisseur des traits arrondis dessinés par un champ.
class _StrokeWidthCollector {
  /// Épaisseurs relevées, dans l'ordre de dessin.
  final List<double> widths = [];

  /// Relève l'épaisseur du trait si [method] dessine un rectangle arrondi.
  ///
  /// - [method] : méthode appelée sur le canvas.
  /// - [arguments] : arguments de cet appel.
  bool collect(Symbol method, List<dynamic> arguments) {
    if (method == #drawRRect) {
      final paint = arguments.last as Paint;
      if (paint.style == PaintingStyle.stroke) {
        widths.add(paint.strokeWidth);
      }
    }
    return true;
  }
}
