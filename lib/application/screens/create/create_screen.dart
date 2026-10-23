import 'dart:async';
import 'dart:io';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_notifier.dart';
import 'package:bedbug/application/screens/create/widgets/content_type_selector.dart';
import 'package:bedbug/application/screens/create/widgets/image_content_form.dart';
import 'package:bedbug/application/screens/create/widgets/link_content_form.dart';
import 'package:bedbug/application/screens/create/widgets/tag_selector.dart';
import 'package:bedbug/application/screens/create/widgets/text_content_form.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:bedbug/features/content/domain/usecases/compress_image_usecase.dart';
import 'package:bedbug/features/content/infrastructure/og_metadata_service.dart';
import 'package:bedbug/shared/config/content_image_storage.dart';
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
  /// Cas d'usage de recompression de l'image choisie avant enregistrement.
  late final _compressImageUsecase = ref.read(compressImageUsecaseProvider);

  /// Contrôle du titre pour [TextContent].
  late final _textTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle du corps pour [TextContent].
  late final _textBodyControl = FormControl<String>(validators: [Validators.required]);

  /// Formulaire pour [TextContent].
  late final FormGroup _textFormGroup = FormGroup({'title': _textTitleControl, 'body': _textBodyControl});

  /// Contrôle de l'image choisie dans la galerie pour [ImageContent].
  late final _imageFileControl = FormControl<XFile>(validators: [Validators.required]);

  /// Contrôle du titre pour [ImageContent].
  late final _imageTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle de la description optionnelle pour [ImageContent].
  late final _imageBodyControl = FormControl<String>();

  /// Formulaire pour [ImageContent].
  late final FormGroup _imageFormGroup = FormGroup({
    'image': _imageFileControl,
    'title': _imageTitleControl,
    'body': _imageBodyControl,
  });

  /// Contrôle du titre pour [LinkContent].
  late final _linkTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle de l'URL pour [LinkContent].
  late final _linkUrlControl = FormControl<String>(validators: [Validators.required]);

  /// Formulaire pour [LinkContent].
  late final FormGroup _linkFormGroup = FormGroup({'title': _linkTitleControl, 'url': _linkUrlControl});

  /// Contrôle des tags sélectionnés, commun aux trois types de contenu.
  late final _tagsControl = FormControl<List<Tag>>(value: const []);

  /// Contrôle du flair libre (ex. `/france`), commun aux trois types de contenu.
  late final _flairControl = FormControl<String>(validators: [AppValidators.flair]);

  /// Compteur incrémenté à chaque changement dans l'un des formulaires.
  final ValueNotifier<int> _formChangeTicker = ValueNotifier<int>(0);

  /// Abonnements aux streams de changement des formulaires.
  late final List<StreamSubscription<dynamic>> _formSubscriptions;

  /// Retourne `true` si le type ne peut plus être changé car des valeurs ont été saisies.
  bool get _isTypeLocked {
    final type = ref.read(createNotifierProvider).requireValue.selectedType;
    return switch (type) {
      ContentType.text => _textTitleControl.value?.isNotEmpty == true || _textBodyControl.value?.isNotEmpty == true,
      ContentType.image => _imageFileControl.value != null,
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
    _tagsControl.dispose();
    _flairControl.dispose();
    super.dispose();
  }

  /// Valide le formulaire actif et déclenche la sauvegarde.
  Future<void> _onSave() async {
    final type = ref.read(createNotifierProvider).requireValue.selectedType;

    // Le flair est commun aux trois types et hors du formulaire actif : il est
    // validé à part, en marquant aussi le formulaire actif pour afficher toutes
    // les erreurs d'un coup.
    if (!_flairControl.valid) {
      _flairControl.markAsTouched();
      _activeFormGroup.markAllAsTouched();
      return;
    }
    final flair = _flairControl.value!.toFlair()!;

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
                displayScore: 1,
                bounce: 0,
                // Placeholder : SaveContentUsecase détermine et corrige le poids réel
                // avant persistance.
                sizeInBytes: 0,
                title: _textTitleControl.value!,
                body: _textBodyControl.value!,
                flair: flair,
                tags: _tagsControl.value ?? const [],
              ),
            );

      case ContentType.image:
        if (!_imageFormGroup.valid) {
          _imageFormGroup.markAllAsTouched();
          return;
        }
        final compressResult = await _compressImageUsecase(
          CompressImageParams(sourcePath: _imageFileControl.value!.path),
        );
        final compressedImage = compressResult.right;
        if (compressedImage == null) {
          if (!mounted) return;
          AppSnackbar.showError(context, AppLocalizations.of(context)!.createImageCompressionError);
          return;
        }

        final dir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${dir.path}/$contentImagesFolder');
        await imagesDir.create(recursive: true);
        final fileName = '${UuidX.generate()}.${compressedImage.fileExtension}';
        final destPath = '${imagesDir.path}/$fileName';
        await File(destPath).writeAsBytes(compressedImage.bytes);

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
                displayScore: 1,
                bounce: 0,
                // Placeholder : SaveContentUsecase détermine et corrige le poids réel
                // (taille du fichier sur disque) avant persistance.
                sizeInBytes: 0,
                fileName: fileName,
                imageWidth: compressedImage.width,
                imageHeight: compressedImage.height,
                title: _imageTitleControl.value!,
                body: _imageBodyControl.value?.isEmpty == true ? null : _imageBodyControl.value,
                flair: flair,
                tags: _tagsControl.value ?? const [],
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
                displayScore: 1,
                bounce: 0,
                sizeInBytes: 0,
                title: _linkTitleControl.value!,
                url: url,
                ogImageUrl: og.imageUrl,
                ogTitle: og.title,
                ogDescription: og.description,
                flair: flair,
                tags: _tagsControl.value ?? const [],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  ReactiveTextField<String>(
                    formControl: _flairControl,
                    maxLength: 32,
                    validationMessages: {'required': (_) => l10n.createFlairRequiredError},
                    decoration: InputDecoration(
                      labelText: l10n.createFlairLabel,
                      hintText: l10n.createFlairHint,
                      prefixText: '/',
                    ),
                  ),
                  Text(l10n.createTagsLabel),
                  TagSelector(control: _tagsControl),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                child: switch (createState.selectedType) {
                  ContentType.text => TextContentForm(titleControl: _textTitleControl, bodyControl: _textBodyControl),
                  ContentType.image => ImageContentForm(
                    imageControl: _imageFileControl,
                    titleControl: _imageTitleControl,
                    bodyControl: _imageBodyControl,
                  ),
                  ContentType.link => LinkContentForm(titleControl: _linkTitleControl, urlControl: _linkUrlControl),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
