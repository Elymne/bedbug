import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_notifier.dart';
import 'package:bedbug/application/screens/create/widgets/content_type_selector.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
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
  late final FormGroup _textFormGroup = FormGroup({'title': _textTitleControl, 'body': _textBodyControl});

  /// Contrôle du titre pour [ImageContent].
  late final _imageTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle de la description optionnelle pour [ImageContent].
  late final _imageBodyControl = FormControl<String>();

  /// Formulaire pour [ImageContent].
  late final FormGroup _imageFormGroup = FormGroup({'title': _imageTitleControl, 'body': _imageBodyControl});

  /// Contrôle du titre pour [LinkContent].
  late final _linkTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle de l'URL pour [LinkContent].
  late final _linkUrlControl = FormControl<String>(validators: [Validators.required]);

  /// Formulaire pour [LinkContent].
  late final FormGroup _linkFormGroup = FormGroup({'title': _linkTitleControl, 'url': _linkUrlControl});

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
        await ref
            .read(createNotifierProvider.notifier)
            .save(
              TextContent(
                id: UuidX.generate(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                authorId: 'local',
                senderId: 'local',
                origin: ContentOrigin.owned,
                broadcastScore: 1,
                survivalScore: 1,
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

        await ref
            .read(createNotifierProvider.notifier)
            .save(
              ImageContent(
                id: UuidX.generate(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                authorId: 'local',
                senderId: 'local',
                origin: ContentOrigin.owned,
                broadcastScore: 1,
                survivalScore: 1,
                bounce: 0,
                sizeInBytes: fileSize,
                fileName: fileName,
                imageWidth: width,
                imageHeight: height,
                title: _imageTitleControl.value!,
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
        await ref
            .read(createNotifierProvider.notifier)
            .save(
              LinkContent(
                id: UuidX.generate(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                authorId: 'local',
                senderId: 'local',
                origin: ContentOrigin.owned,
                broadcastScore: 1,
                survivalScore: 1,
                bounce: 0,
                sizeInBytes: 0,
                title: _linkTitleControl.value!,
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
      if (!context.mounted) return;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: Row(
                children: [
                  const AppCloseButton(),
                  const Spacer(),
                  AppGradientButton(
                    isLoading: ref.watch(createNotifierProvider).isLoading,
                    onTap: _onSave,
                    child: Text(l10n.createSaveButton),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: ListenableBuilder(
                listenable: _formChangeTicker,
                builder: (context, _) {
                  return ContentTypeSelector(
                    selectedType: createState.selectedType,
                    isLocked: _isTypeLocked,
                    onTypeSelected: ref.read(createNotifierProvider.notifier).setType,
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
            child: Image.file(File(_pickedImage!.path), width: double.infinity, fit: BoxFit.cover),
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
          formControlName: 'title',
          decoration: InputDecoration(labelText: l10n.createTextTitleLabel),
        ),
        ReactiveTextField<String>(
          formControlName: 'url',
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.createLinkUrlLabel),
        ),
      ],
    );
  }
}
