import 'package:bedbug/application/screens/signature/signature_contents/signature_contents.widget.dart';
import 'package:bedbug/application/screens/signature/signature_header/signature_header.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page d'une signature : son bedbug en grand, son pseudo, ses réseaux, puis les contenus qu'elle a signés.
///
/// Ouverte depuis les suggestions de la recherche, ou depuis la page de détail
/// d'un contenu en touchant le pseudo ou le bedbug de son auteur. L'en-tête défile avec la
/// liste des contenus, pour que le grand bedbug ne prenne pas toute la place.
///
/// Page statique : l'en-tête et la liste observent chacun leur état.
class SignatureScreen extends ConsumerWidget {
  /// Crée un [SignatureScreen].
  ///
  /// - [signatureId] : identifiant de la signature affichée.
  const SignatureScreen({super.key, required this.signatureId});

  /// Identifiant de la signature affichée.
  final String signatureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [SliverToBoxAdapter(child: SignatureHeader(signatureId: signatureId))];
          },
          body: SignatureContents(signatureId: signatureId),
        ),
      ),
    );
  }
}
