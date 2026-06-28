import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/buttons/app_loading_button.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_priority.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:bedbug/features/content/infrastructure/og_metadata_service.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Page de création de contenu.
class CreateScreen extends ConsumerStatefulWidget {
  /// Crée un [CreateScreen].
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _State();
}

class _State extends ConsumerState<CreateScreen> {
  /// Contrôle du titre pour [TextContent].
  late final _textTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle du corps pour [TextContent].
  late final _textBodyControl = FormControl<String>(validators: [Validators.required]);

  /// Formulaire pour [TextContent].
  late final FormGroup _textFormGroup = FormGroup({
    'title': _textTitleControl,
    'body': _textBodyControl,
  });

  /// Contrôle du titre optionnel pour [ImageContent].
  late final _imageTitleControl = FormControl<String>();

  /// Contrôle de la description optionnelle pour [ImageContent].
  late final _imageBodyControl = FormControl<String>();

  /// Formulaire pour [ImageContent].
  late final FormGroup _imageFormGroup = FormGroup({
    'title': _imageTitleControl,
    'body': _imageBodyControl,
  });

  /// Contrôle de l'URL pour [LinkContent].
  late final _linkUrlControl = FormControl<String>(validators: [Validators.required]);

  /// Formulaire pour [LinkContent].
  late final FormGroup _linkFormGroup = FormGroup({
    'url': _linkUrlControl,
  });

  /// Image sélectionnée par l'utilisateur pour [ImageContent].
  XFile? _pickedImage;

  /// Compteur incrémenté à chaque changement dans l'un des formulaires ou lors d'un pick d'image.
  final ValueNotifier<int> _formChangeTicker = ValueNotifier<int>(0);

  /// Abonnements aux streams de changement des formulaires.
  late final List<StreamSubscription<dynamic>> _formSubscriptions;

  /// Retourne `true` si le type ne peut plus être changé car des valeurs ont été saisies.
  bool get _isTypeLocked {
    final type = ref.read(createNotifierProvider).requireValue.selectedType;
    return switch (type) {
      ContentType.text => _textTitleControl.value?.isNotEmpty == true || _textBodyControl.value?.isNotEmpty == true,
      ContentType.image => _pickedImage != null,
      ContentType.link => _linkUrlControl.value?.isNotEmpty == true,
    };
  }

  /// Retourne le formulaire actif selon le type sélectionné.
  FormGroup get _activeFormGroup {
    final type = ref.read(createNotifierProvider).requireValue.selectedType;
    return switch (type) {
      ContentType.text => _textFormGroup,
      ContentType.image => _imageFormGroup,
      ContentType.link => _linkFormGroup,
    };
  }

  @override
  void initState() {
    super.initState();
    _formSubscriptions = [
      _textFormGroup.valueChanges.listen((_) => _formChangeTicker.value++),
      _imageFormGroup.valueChanges.listen((_) => _formChangeTicker.value++),
      _linkFormGroup.valueChanges.listen((_) => _formChangeTicker.value++),
    ];
  }

  @override
  void dispose() {
    for (final sub in _formSubscriptions) {
      sub.cancel();
    }
    _formChangeTicker.dispose();
    _textFormGroup.dispose();
    _imageFormGroup.dispose();
    _linkFormGroup.dispose();
    super.dispose();
  }

  /// Ouvre le sélecteur d'image de la galerie.
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    _pickedImage = image;
    _formChangeTicker.value++;
  }

  /// Valide le formulaire actif et déclenche la sauvegarde.
  Future<void> _onSave() async {
    final type = ref.read(createNotifierProvider).requireValue.selectedType;

    switch (type) {
      case ContentType.text:
        if (!_textFormGroup.valid) {
          _textFormGroup.markAllAsTouched();
          return;
        }
        await ref.read(createNotifierProvider.notifier).save(
          TextContent(
            id: UuidX.generate(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            authorId: 'local',
            senderId: 'local',
            priority: ContentPriority.owned,
            bounce: 0,
            sizeInBytes: (_textBodyControl.value ?? '').length,
            title: _textTitleControl.value!,
            body: _textBodyControl.value!,
          ),
        );

      case ContentType.image:
        if (_pickedImage == null) return;
        final bytes = await _pickedImage!.readAsBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        final width = descriptor.width;
        final height = descriptor.height;
        descriptor.dispose();
        buffer.dispose();

        final dir = await getApplicationDocumentsDirectory();
        final ext = _pickedImage!.path.split('.').last;
        final fileName = '${UuidX.generate()}.$ext';
        final destPath = '${dir.path}/$fileName';
        await File(_pickedImage!.path).copy(destPath);
        final fileSize = await File(destPath).length();

        await ref.read(createNotifierProvider.notifier).save(
          ImageContent(
            id: UuidX.generate(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            authorId: 'local',
            senderId: 'local',
            priority: ContentPriority.owned,
            bounce: 0,
            sizeInBytes: fileSize,
            fileName: fileName,
            imageWidth: width,
            imageHeight: height,
            title: _imageTitleControl.value?.isEmpty == true ? null : _imageTitleControl.value,
            body: _imageBodyControl.value?.isEmpty == true ? null : _imageBodyControl.value,
          ),
        );

      case ContentType.link:
        if (!_linkFormGroup.valid) {
          _linkFormGroup.markAllAsTouched();
          return;
        }
        final url = _linkUrlControl.value!;
        final og = await ref.read(ogMetadataServiceProvider).fetch(url);
        await ref.read(createNotifierProvider.notifier).save(
          LinkContent(
            id: UuidX.generate(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            authorId: 'local',
            senderId: 'local',
            priority: ContentPriority.owned,
            bounce: 0,
            sizeInBytes: 0,
            url: url,
            ogImageUrl: og.imageUrl,
            ogTitle: og.title,
            ogDescription: og.description,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final createWatcher = ref.watch(createNotifierProvider);

    ref.listen(createNotifierProvider, (previous, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        AppSnackbar.showError(context, l10n.createSaveError);
        return;
      }
      final createState = next.value!;
      if (createState.isSuccess) {
        AppSnackbar.showSuccess(context, l10n.createSuccessMessage);
        context.pop();
        return;
      }
      if (createState.failureMessage != null) {
        AppSnackbar.showError(context, createState.failureMessage!);
      }
    });

    return createWatcher.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (createState) => _buildContent(context, l10n, createState),
    );
  }

  /// Construit le contenu principal de la page.
  Widget _buildContent(BuildContext context, AppLocalizations l10n, CreateState createState) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: l10n.createTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: ListenableBuilder(
                listenable: _formChangeTicker,
                builder: (context, _) {
                  final isLocked = _isTypeLocked;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      _TypeToggleButton(
                        label: l10n.createTypeText,
                        isSelected: createState.selectedType == ContentType.text,
                        isDisabled: isLocked && createState.selectedType != ContentType.text,
                        onTap: () => ref.read(createNotifierProvider.notifier).setType(ContentType.text),
                      ),
                      _TypeToggleButton(
                        label: l10n.createTypeImage,
                        isSelected: createState.selectedType == ContentType.image,
                        isDisabled: isLocked && createState.selectedType != ContentType.image,
                        onTap: () => ref.read(createNotifierProvider.notifier).setType(ContentType.image),
                      ),
                      _TypeToggleButton(
                        label: l10n.createTypeLink,
                        isSelected: createState.selectedType == ContentType.link,
                        isDisabled: isLocked && createState.selectedType != ContentType.link,
                        onTap: () => ref.read(createNotifierProvider.notifier).setType(ContentType.link),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                child: ReactiveForm(
                  key: ValueKey(createState.selectedType),
                  formGroup: _activeFormGroup,
                  child: switch (createState.selectedType) {
                    ContentType.text => _buildTextForm(l10n),
                    ContentType.image => _buildImageForm(l10n),
                    ContentType.link => _buildLinkForm(l10n),
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppValues.baseMargin),
              child: AppLoadingButton(
                isLoading: ref.watch(createNotifierProvider).isLoading,
                onTap: _onSave,
                loadingChild: Text(l10n.createSaveLoading),
                child: Text(l10n.createSaveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formulaire de création d'un [TextContent].
  Widget _buildTextForm(AppLocalizations l10n) {
    return Column(
      spacing: 16,
      children: [
        ReactiveTextField<String>(
          formControlName: 'title',
          decoration: InputDecoration(labelText: l10n.createTextTitleLabel),
        ),
        ReactiveTextField<String>(
          formControlName: 'body',
          maxLines: 6,
          decoration: InputDecoration(labelText: l10n.createTextBodyLabel),
        ),
      ],
    );
  }

  /// Formulaire de création d'un [ImageContent].
  Widget _buildImageForm(AppLocalizations l10n) {
    return Column(
      spacing: 16,
      children: [
        if (_pickedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_pickedImage!.path),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_outlined),
          label: Text(l10n.createImagePickLabel),
        ),
        ReactiveTextField<String>(
          formControlName: 'title',
          decoration: InputDecoration(labelText: l10n.createImageTitleLabel),
        ),
        ReactiveTextField<String>(
          formControlName: 'body',
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.createImageBodyLabel),
        ),
      ],
    );
  }

  /// Formulaire de création d'un [LinkContent].
  Widget _buildLinkForm(AppLocalizations l10n) {
    return Column(
      spacing: 16,
      children: [
        ReactiveTextField<String>(
          formControlName: 'url',
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.createLinkUrlLabel),
        ),
      ],
    );
  }
}

/// Bouton toggle de sélection du type de contenu avec effet ghost animé.
class _TypeToggleButton extends ConsumerStatefulWidget {
  /// Crée un [_TypeToggleButton].
  ///
  /// - [label] : texte affiché dans le bouton.
  /// - [isSelected] : `true` si ce type est actuellement sélectionné.
  /// - [isDisabled] : `true` si le type est verrouillé et non sélectionnable.
  /// - [onTap] : callback déclenché lors du tap si non désactivé.
  const _TypeToggleButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  /// Texte du bouton.
  final String label;

  /// Indique si ce bouton est sélectionné.
  final bool isSelected;

  /// Indique si ce bouton est désactivé (type verrouillé).
  final bool isDisabled;

  /// Callback déclenché au tap.
  final VoidCallback onTap;

  @override
  ConsumerState<_TypeToggleButton> createState() => _TypeToggleButtonState();
}

class _TypeToggleButtonState extends ConsumerState<_TypeToggleButton> with TickerProviderStateMixin {
  /// Contrôleur de la pulsation du ghost.
  late final AnimationController _pulseController = AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  );

  /// Contrôleur du léger tremblement du ghost.
  late final AnimationController _trembleController = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isSelected) _startAnimations();
  }

  @override
  void didUpdateWidget(_TypeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _startAnimations();
      return;
    }
    if (!widget.isSelected && oldWidget.isSelected) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _trembleController.dispose();
    super.dispose();
  }

  /// Démarre les animations en boucle.
  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _trembleController.repeat(reverse: true);
  }

  /// Arrête et remet à zéro les animations.
  void _stopAnimations() {
    _pulseController.stop();
    _trembleController.stop();
    _pulseController.reset();
    _trembleController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDisabled ? null : widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: widget.isSelected ? _buildGhostLabel() : _buildNormalLabel(),
      ),
    );
  }

  /// Label sans effet (non sélectionné).
  Widget _buildNormalLabel() {
    return Text(
      widget.label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: widget.isDisabled ? AppColors.disabled : AppColors.onLight,
      ),
    );
  }

  /// Label avec effet ghost animé (sélectionné).
  Widget _buildGhostLabel() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _trembleController]),
      builder: (context, _) {
        final ghostOffset = Offset(2.0 * _trembleController.value, 1.2 * _trembleController.value);
        final mainOffset = Offset(0.8 * _trembleController.value, 0.4 * _trembleController.value);
        const style = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

        return Stack(
          children: [
            Transform.translate(
              offset: ghostOffset,
              child: Text(widget.label, style: style.copyWith(color: AppColors.primary)),
            ),
            Transform.translate(
              offset: mainOffset,
              child: Text(widget.label, style: style.copyWith(color: AppColors.onLight)),
            ),
          ],
        );
      },
    );
  }
}
