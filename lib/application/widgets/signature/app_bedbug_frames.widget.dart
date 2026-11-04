import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Durée d'affichage de chaque frame d'un bedbug animé, à la vitesse normale.
const Duration _kFrameDuration = Duration(milliseconds: 400);

/// Bedbug affiché frame après frame : chaque frame est un texte, et le bedbug s'anime en passant de l'une à l'autre.
///
/// Le widget prend la taille de sa frame la plus large : sans cela, un bedbug dont une frame est plus longue (un bras
/// qui se tend) ferait sauter tout ce qui l'entoure à chaque changement. Un bedbug d'une seule frame, ou figé, est un
/// simple texte.
class AppBedbugFrames extends ConsumerStatefulWidget {
  /// Crée un [AppBedbugFrames].
  ///
  /// - [frames] : frames du bedbug, affichées tour à tour. Au moins une.
  /// - [style] : style du texte de chaque frame.
  /// - [speed] : multiplicateur de la vitesse normale de l'animation, strictement positif (défaut 1).
  /// - [isAnimating] : `false` pour figer le bedbug sur sa première frame (défaut `true`).
  /// - [alignment] : placement d'une frame plus étroite que la plus large (défaut [Alignment.center]).
  const AppBedbugFrames({
    super.key,
    required this.frames,
    required this.style,
    this.speed = 1,
    this.isAnimating = true,
    this.alignment = Alignment.center,
  });

  /// Frames du bedbug, affichées tour à tour.
  final List<String> frames;

  /// Style du texte de chaque frame.
  final TextStyle style;

  /// Multiplicateur de la vitesse normale de l'animation : 2 fait défiler les frames deux fois plus vite.
  final double speed;

  /// Indique si le bedbug passe d'une frame à l'autre.
  final bool isAnimating;

  /// Placement d'une frame plus étroite que la plus large.
  ///
  /// Centrée par défaut. Calée au début, elle garde son bord gauche fixe : un texte qui s'allonge d'une frame à
  /// l'autre (des `z` qui s'accumulent) grandit alors vers la droite sans bouger.
  final AlignmentGeometry alignment;

  @override
  ConsumerState<AppBedbugFrames> createState() => _State();
}

class _State extends ConsumerState<AppBedbugFrames> {
  /// Battement de l'animation : le numéro du battement, qui donne la frame affichée.
  ///
  /// Gardé par l'état pour ne pas repartir de la première frame à chaque reconstruction du parent, et recréé
  /// seulement quand la vitesse change. N'émet rien tant que personne ne l'écoute : un bedbug fixe ne coûte aucun
  /// minuteur.
  late Stream<int> _ticks = _createTicks();

  @override
  void didUpdateWidget(AppBedbugFrames oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pas de setState : la reconstruction suit d'elle-même un didUpdateWidget.
    if (oldWidget.speed != widget.speed) {
      _ticks = _createTicks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating || widget.frames.length < 2) {
      return Text(widget.frames.first, style: widget.style);
    }

    return StreamBuilder<int>(
      stream: _ticks,
      initialData: 0,
      builder: (context, snapshot) {
        return IndexedStack(
          alignment: widget.alignment,
          index: (snapshot.data ?? 0) % widget.frames.length,
          children: [for (final frame in widget.frames) Text(frame, style: widget.style)],
        );
      },
    );
  }

  /// Retourne un battement au rythme de la vitesse actuelle du widget.
  Stream<int> _createTicks() {
    return Stream<int>.periodic(_kFrameDuration * (1 / widget.speed), (tick) => tick + 1);
  }
}
