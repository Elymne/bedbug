import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rayon des coins arrondis du champ de recherche.
const _kBorderRadius = 24.0;

/// Épaisseur de la bordure au focus.
const _kBorderWidth = 2.0;

/// Hauteur fixe du champ de recherche.
const _kHeight = 52.0;

/// Widget de recherche pour filtrer les contenus de la liste.
class ContentSearchInput extends ConsumerStatefulWidget {
  /// Crée un [ContentSearchInput].
  ///
  /// - [hintText] : texte affiché en placeholder.
  const ContentSearchInput({super.key, required this.hintText});

  /// Texte affiché en placeholder.
  final String hintText;

  @override
  ConsumerState<ContentSearchInput> createState() => _State();
}

class _State extends ConsumerState<ContentSearchInput> with TickerProviderStateMixin {
  /// Contrôleur du champ de texte.
  late final TextEditingController _controller = TextEditingController();

  /// Nœud de focus pour détecter l'état actif du champ.
  late final FocusNode _focusNode = FocusNode();

  /// Contrôleur du tremblement du layer principal.
  late final AnimationController _trembleController = AnimationController(
    duration: const Duration(milliseconds: 2400),
    vsync: this,
  );

  /// Contrôleur du tremblement du ghost, plus lent et déphasé.
  late final AnimationController _ghostTrembleController = AnimationController(
    duration: const Duration(milliseconds: 1800),
    vsync: this,
  );

  /// Notifier local gérant l'état de focus du champ.
  late final _FocusNotifier _focusNotifier = _FocusNotifier();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _trembleController.dispose();
    _ghostTrembleController.dispose();
    _focusNotifier.dispose();
    super.dispose();
  }

  /// Démarre ou arrête les animations selon l'état du focus.
  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    _focusNotifier.setFocused(isFocused);
    if (isFocused) {
      _trembleController.repeat(reverse: true);
      _ghostTrembleController.repeat(reverse: true);
      return;
    }
    _trembleController.stop();
    _ghostTrembleController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_trembleController, _ghostTrembleController, _focusNotifier]),
      builder: (context, child) {
        final trembleValue = _trembleController.value * 2 - 1;
        final ghostTrembleValue = _ghostTrembleController.value * 2 - 1;

        final trembleOffset = Offset(trembleValue * 0.8, trembleValue * 0.3);
        final ghostTrembleOffset = Offset(ghostTrembleValue * 1.5, ghostTrembleValue * 0.6);

        return SizedBox(
          height: _kHeight,
          child: Stack(
            children: [
              // Ghost — bordure primaire décalée et tremblante.
              AnimatedOpacity(
                opacity: _focusNotifier.isFocused ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Transform.translate(
                  offset: ghostTrembleOffset + const Offset(2.5, 2.0),
                  child: Container(
                    height: _kHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_kBorderRadius),
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              // Layer principal — bordure + row de contenu centré.
              Transform.translate(
                offset: _focusNotifier.isFocused ? trembleOffset : Offset.zero,
                child: Container(
                  height: _kHeight,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(_kBorderRadius),
                    border: Border.all(color: AppColors.onLight, width: _kBorderWidth),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      return Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 20,
                            color: _focusNotifier.isFocused ? AppColors.primary : AppColors.onLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              style: AppTextStyles.textfield,
                              decoration: InputDecoration(
                                hintText: widget.hintText,
                                hintStyle: AppTextStyles.textfield.copyWith(color: AppColors.disabled),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: _controller.clear,
                              child: const Icon(Icons.close, size: 18, color: AppColors.disabled),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Notifier local gérant l'état de focus du champ de recherche.
class _FocusNotifier extends ChangeNotifier {
  /// Indique si le champ est actuellement actif.
  bool isFocused = false;

  /// Met à jour l'état de focus et notifie les listeners si la valeur change.
  ///
  /// - [value] : nouvel état de focus.
  void setFocused(bool value) {
    if (value == isFocused) return;
    isFocused = value;
    notifyListeners();
  }
}
