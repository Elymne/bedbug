import 'package:bedbug/application/screens/exchange/exchange_stats/exchange_stats.widget.dart';
import 'package:bedbug/application/screens/exchange/exchange_toggle/exchange_toggle.widget.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'activation de l'échange de contenus avec les téléphones proches.
///
/// Page statique : la case d'activation et les compteurs observent chacun leur état.
class ExchangeScreen extends ConsumerWidget {
  /// Crée un [ExchangeScreen].
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: context.loc.navExchangeLabel, onBack: context.pop),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [ExchangeToggle(), ExchangeStats()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
