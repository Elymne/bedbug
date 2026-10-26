import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Pas du curseur entre [minGhostSpeed] et [maxGhostSpeed].
const double _kGhostSpeedStep = 0.25;

/// Curseur de l'intensité d'un effet ghost, présentée comme sa « force » (multiplicateur de vitesse).
///
/// Sert pour la signature comme pour le bedbug d'une réaction : les bornes et
/// le pas restent ainsi les mêmes partout, et toujours ceux du domaine.
class AppGhostSpeedSlider extends ConsumerWidget {
  /// Crée un [AppGhostSpeedSlider].
  ///
  /// - [formControl] : contrôle portant la vitesse choisie.
  const AppGhostSpeedSlider({super.key, required this.formControl});

  /// Contrôle portant la vitesse choisie.
  final FormControl<double> formControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveSlider(
      formControl: formControl,
      min: minGhostSpeed,
      max: maxGhostSpeed,
      divisions: ((maxGhostSpeed - minGhostSpeed) / _kGhostSpeedStep).round(),
      labelBuilder: (value) => '×${value.toStringAsFixed(2)}',
    );
  }
}
