import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rayon des coins arrondis du champ de recherche.
const _kBorderRadius = 24.0;

/// Épaisseur de la bordure.
const _kBorderWidth = 1.0;

/// Hauteur fixe du champ de recherche.
const _kHeight = 52.0;

/// Widget de recherche pour filtrer les contenus de la liste.
class ContentSearchInput extends ConsumerStatefulWidget {
  /// Crée un [ContentSearchInput].
  ///
  /// - [hintText] : texte affiché en placeholder.
  /// - [isReadOnly] : si `true`, le champ se comporte comme un bouton — il
  ///   n'ouvre jamais le clavier et se contente de déclencher [onTap]. Sert
  ///   de leurre sur la home page, à la manière de la barre de recherche de
  ///   Reddit, pour renvoyer vers l'écran de recherche dédié.
  /// - [onTap] : callback déclenché au tap quand [isReadOnly] est `true`.
  /// - [autofocus] : si `true`, ouvre le clavier automatiquement dès le montage du widget.
  /// - [isDark] : si `true`, applique le variant sombre (fond sombre, sans
  ///   contour, texte et icônes en [AppColors.onDark]) destiné aux écrans à
  ///   fond sombre comme `SearchScreen`. `false` par défaut pour l'usage sur
  ///   fond clair (home page, leurre).
  const ContentSearchInput({
    super.key,
    required this.hintText,
    this.isReadOnly = false,
    this.onTap,
    this.autofocus = false,
    this.isDark = false,
  });

  /// Texte affiché en placeholder.
  final String hintText;

  /// Si `true`, le champ se comporte comme un bouton plutôt qu'un vrai champ de saisie.
  final bool isReadOnly;

  /// Callback déclenché au tap quand [isReadOnly] est `true`.
  final VoidCallback? onTap;

  /// Si `true`, ouvre le clavier automatiquement dès le montage du widget.
  final bool autofocus;

  /// Si `true`, applique le variant sombre du champ.
  final bool isDark;

  @override
  ConsumerState<ContentSearchInput> createState() => _State();
}

class _State extends ConsumerState<ContentSearchInput> {
  /// Contrôleur du champ de texte.
  late final TextEditingController _controller = TextEditingController();

  /// Nœud de focus pour détecter l'état actif du champ.
  late final FocusNode _focusNode = FocusNode();

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
    _focusNotifier.dispose();
    super.dispose();
  }

  /// Met à jour l'état de focus affiché.
  ///
  /// Sans effet en mode bouton ([ContentSearchInput.isReadOnly]) : ce champ
  /// ne doit jamais déclencher le changement d'apparence, puisqu'il ne reçoit
  /// jamais réellement le focus clavier.
  void _onFocusChanged() {
    if (widget.isReadOnly) return;
    _focusNotifier.setFocused(_focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark ? AppColors.onLight : AppColors.surface;
    final textColor = widget.isDark ? AppColors.onDark : AppColors.onLight;
    final iconColor = widget.isDark ? AppColors.onDark : AppColors.onLight;

    return AnimatedBuilder(
      animation: _focusNotifier,
      builder: (context, child) {
        return Container(
          height: _kHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_kBorderRadius),
            border: widget.isDark ? null : Border.all(color: AppColors.primary, width: _kBorderWidth),
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
                    color: _focusNotifier.isFocused && !widget.isDark ? AppColors.primary : iconColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      readOnly: widget.isReadOnly,
                      showCursor: widget.isReadOnly ? false : null,
                      autofocus: widget.autofocus,
                      onTap: widget.isReadOnly ? widget.onTap : null,
                      style: AppTextStyles.textfield.copyWith(color: textColor),
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
                      child: Icon(Icons.close, size: 18, color: widget.isDark ? iconColor : AppColors.disabled),
                    ),
                ],
              );
            },
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
