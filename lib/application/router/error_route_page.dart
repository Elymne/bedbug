import 'package:bedbug/application/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page d'erreur générique affichant un [message] donné par l'appelant.
///
/// Utilisée par le router pour signaler toute situation
/// anormale (route inconnue, accès refusé, erreur d'authentification, etc.).
class ErrorRoutePage extends StatelessWidget {
  /// Crée une [ErrorRoutePage].
  const ErrorRoutePage({required this.message, super.key});

  /// Message d'erreur à afficher à l'utilisateur.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.go(homePath),
              icon: const Icon(Icons.arrow_back),
              label: const Text('context.loc.errorRouteBackButton'),
            ),
          ],
        ),
      ),
    );
  }
}
