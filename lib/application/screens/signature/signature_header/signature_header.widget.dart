import 'package:bedbug/application/notifiers/content_author.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.widget.dart';
import 'package:bedbug/application/widgets/signature/app_signature_bio.widget.dart';
import 'package:bedbug/application/widgets/tags/app_tag.widget.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.widget.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur maximale du bedbug en tête de page.
///
/// Le bedbug prend toute la largeur disponible, mais une émote très courte
/// (`ʕ•ᴥ•ʔ`) deviendrait alors démesurément haute : on le plafonne.
const double _kMaxBedbugHeight = 140;

/// En-tête de la page d'une signature : retour, son bedbug en grand, son pseudo, sa description et ses réseaux.
///
/// Seule partie de la page à observer la signature. Le temps de la charger, on présente la signature anonyme : la
/// mise en page reste stable au lieu de sauter une fois la signature chargée.
class SignatureHeader extends ConsumerWidget {
  /// Crée un [SignatureHeader].
  ///
  /// - [signatureId] : identifiant de la signature affichée.
  const SignatureHeader({super.key, required this.signatureId});

  /// Identifiant de la signature affichée.
  final String signatureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(signatureId));
    final signature = contentAuthorNotifierWatcher.value ?? anonymousSignature;
    final colorArgb = signature.colorArgb;
    final ghostColor = colorArgb == null ? AppColors.primary : Color(colorArgb);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              onPressed: context.pop,
              icon: const AppIcon(AppIcons.arrowBack, color: AppColors.onLight),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _kMaxBedbugHeight),
            child: FittedBox(
              child: Padding(
                // Laisse la place au tremblement du ghost, qui
                // déborde légèrement du texte.
                padding: const EdgeInsets.all(4),
                child: AppSignatureAvatar(
                  avatarFrames: signature.avatarFrames,
                  avatarFrameSpeed: signature.avatarFrameSpeed,
                  ghostColor: ghostColor,
                  ghostSpeed: signature.ghostSpeed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppPrefixedText(
            prefix: signaturePrefix,
            text: signature.pseudo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onLight),
          ),
          if (signature.bio != null) ...[
            const SizedBox(height: 8),
            AppSignatureBio(bio: signature.bio!, font: signature.bioFont),
          ],
          if (signature.socialLinks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final network in signature.socialLinks.keys)
                  AppTag(label: network.displayName, colors: [ghostColor]),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
