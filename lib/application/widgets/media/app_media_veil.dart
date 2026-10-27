import 'dart:ui';

import 'package:bedbug/application/notifiers/revealed_urls_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/dialogs/trust_confirm_dialog.dart';
import 'package:bedbug/application/widgets/media/app_media_placeholder.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Intensité du flou d'un média en greylist.
///
/// Assez pour ne rien reconnaître de choquant, assez peu pour deviner s'il
/// s'agit d'une photo, d'un dessin ou d'une capture.
const double _kBlurSigma = 14;

/// Voile posé sur un média qui demande une confirmation avant d'être affiché.
///
/// Un média en greylist est chargé mais flouté ([blurredChild]) : son
/// domaine est accepté, mais pas sûr à chaque fois, et l'utilisateur peut
/// regarder les réactions avant de se décider. Un média d'un domaine
/// inconnu n'est, lui, même pas chargé : le voile n'affiche que son
/// domaine. Dans les deux cas, un tap demande confirmation, puis dévoile le
/// média pour le reste de la session.
class AppMediaVeil extends ConsumerWidget {
  /// Crée un [AppMediaVeil].
  ///
  /// - [url] : adresse du média voilé, telle que reçue.
  /// - [host] : domaine du média, cité à l'utilisateur.
  /// - [blurredChild] : média à flouter (greylist), `null` si le média ne doit pas être chargé (domaine inconnu).
  const AppMediaVeil({super.key, required this.url, required this.host, this.blurredChild});

  /// Adresse du média voilé, telle que reçue.
  final String url;

  /// Domaine du média, cité à l'utilisateur.
  final String host;

  /// Média à flouter, `null` si le média ne doit pas être chargé.
  final Widget? blurredChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    Widget veil = AppMediaPlaceholder(icon: Icons.visibility_off_outlined, label: l10n.mediaHiddenLabel(host));
    if (blurredChild != null) {
      veil = Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: _kBlurSigma, sigmaY: _kBlurSigma),
              child: blurredChild,
            ),
          ),
          const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.barrier, shape: BoxShape.circle),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.visibility_outlined, color: AppColors.onDark),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: l10n.mediaRevealTitle,
      child: GestureDetector(onTap: () => _confirmReveal(context, ref), child: veil),
    );
  }

  /// Demande confirmation, puis dévoile le média pour le reste de la session.
  Future<void> _confirmReveal(BuildContext context, WidgetRef ref) async {
    final l10n = context.loc;
    final isConfirmed = await TrustConfirmDialog.show(
      context,
      title: l10n.mediaRevealTitle,
      body: l10n.mediaRevealBody(host),
      confirmLabel: l10n.mediaRevealConfirm,
    );
    if (isConfirmed) {
      ref.read(revealedUrlsNotifierProvider.notifier).reveal(url);
    }
  }
}
