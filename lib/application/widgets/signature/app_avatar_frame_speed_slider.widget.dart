import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Pas du curseur entre [minAvatarFrameSpeed] et [maxAvatarFrameSpeed].
const double _kAvatarFrameSpeedStep = 0.25;

/// Curseur de la vitesse de l'animation d'un bedbug (multiplicateur de la vitesse normale).
///
/// Sert pour la signature comme pour le bedbug d'une réaction, à la manière d'`AppGhostSpeedSlider` : les bornes et
/// le pas restent ainsi les mêmes partout, et toujours ceux du domaine.
class AppAvatarFrameSpeedSlider extends ConsumerWidget {
  /// Crée un [AppAvatarFrameSpeedSlider].
  ///
  /// - [formControl] : contrôle portant la vitesse choisie.
  const AppAvatarFrameSpeedSlider({super.key, required this.formControl});

  /// Contrôle portant la vitesse choisie.
  final FormControl<double> formControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReactiveSlider(
      formControl: formControl,
      min: minAvatarFrameSpeed,
      max: maxAvatarFrameSpeed,
      divisions: ((maxAvatarFrameSpeed - minAvatarFrameSpeed) / _kAvatarFrameSpeedStep).round(),
      labelBuilder: (value) => '×${value.toStringAsFixed(2)}',
    );
  }
}
