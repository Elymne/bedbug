import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Accès aux outils de debug.
class DebugSection extends ConsumerWidget {
  /// Crée un [DebugSection].
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.loc.exchangeLogsTitle, style: const TextStyle(fontSize: 15, color: AppColors.onLight)),
      trailing: const AppIcon(AppIcons.chevronRight, color: AppColors.onLight),
      onTap: () => context.push(exchangeLogsPath),
    );
  }
}
