import 'package:bedbug/application/screens/exchange/exchange_scene/exchange_scene.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page d'activation de l'échange de contenus avec les téléphones proches.
///
/// Page statique : toute la page est une scène de jour et de nuit, qui porte son en-tête et observe elle-même l'état
/// de l'échange. Les statistiques des échanges sont dans les paramètres.
class ExchangeScreen extends ConsumerWidget {
  /// Crée un [ExchangeScreen].
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: ExchangeScene());
  }
}
