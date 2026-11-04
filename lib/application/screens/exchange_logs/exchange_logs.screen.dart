import 'package:bedbug/application/screens/exchange_logs/exchange_logs_list/exchange_logs_list.widget.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de debug : le journal des rencontres avec les pairs.
///
/// Page statique : la liste observe elle-même le journal.
class ExchangeLogsScreen extends ConsumerWidget {
  /// Crée un [ExchangeLogsScreen].
  const ExchangeLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: context.loc.exchangeLogsTitle, onBack: context.pop),
            const Expanded(child: ExchangeLogsList()),
          ],
        ),
      ),
    );
  }
}
