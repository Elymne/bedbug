import 'dart:async';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/create/create_notifier.dart';
import 'package:bedbug/application/screens/create/publish_content_notifier.dart';
import 'package:bedbug/application/screens/create/widgets/content_type_selector.dart';
import 'package:bedbug/application/screens/create/widgets/link_content_form.dart';
import 'package:bedbug/application/screens/create/widgets/media_content_form.dart';
import 'package:bedbug/application/screens/create/widgets/tag_selector.dart';
import 'package:bedbug/application/screens/create/widgets/text_content_form.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/validators/app_validators.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/application/widgets/texts/app_loading_text.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:bedbug/features/content/domain/services/media_kind_service.dart';
import 'package:bedbug/features/content/infrastructure/og_metadata_service.dart';
import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  /// Contrôle des adresses des médias pour [MediaContent], dans l'ordre d'affichage.
  late final _mediaUrlsControl = FormControl<List<String>>(value: const [], validators: [AppValidators.required]);

  /// Contrôle du titre pour [MediaContent].
  late final _mediaTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle de la description optionnelle pour [MediaContent].
  late final _mediaBodyControl = FormControl<String>();

  /// Formulaire pour [MediaContent].
  late final FormGroup _mediaFormGroup = FormGroup({
    'media': _mediaUrlsControl,
    'title': _mediaTitleControl,
    'body': _mediaBodyControl,
  });

  /// Contrôle du titre pour [LinkContent].
  late final _linkTitleControl = FormControl<String>(validators: [Validators.required]);

  /// Contrôle de l'URL pour [LinkContent].
  late final _linkUrlControl = FormControl<String>(validators: [Validators.required, AppValidators.safeUrl]);

  /// Formulaire pour [LinkContent].
  late final FormGroup _linkFormGroup = FormGroup({'title': _linkTitleControl, 'url': _linkUrlControl});

  /// Contrôle des tags sélectionnés, commun aux trois types de contenu.
  late final _tagsControl = FormControl<List<Tag>>(value: const []);

  /// Contrôle du flair libre (ex. `/france`), commun aux trois types de contenu.
  late final _flairControl = FormControl<String>(validators: [AppValidators.flair]);

  /// Contrôle « publier en anonyme », commun aux trois types de contenu.
  ///
  /// Sa valeur initiale vient des réglages (publication anonyme par défaut),
  /// appliquée une seule fois dès que le notifier les a chargés.
  late final _isAnonymousControl = FormControl<bool>(value: false);

  /// Indique si la valeur par défaut de [_isAnonymousControl] a déjà été appliquée.
  ///
  /// Évite d'écraser le choix de l'utilisateur quand l'état du notifier
  /// change ensuite (sélection du type, tentative de sauvegarde).
  bool _isAnonymousDefaultApplied = false;

  /// Compteur incrémenté à chaque changement dans l'un des formulaires.
  final ValueNotifier<int> _formChangeTicker = ValueNotifier<int>(0);

  /// Abonnements aux streams de changement des formulaires.
  late final List<StreamSubscription<dynamic>> _formSubscriptions;

  /// Retourne `true` si le type ne peut plus être changé car des valeurs ont été saisies.
  bool get _isTypeLocked {
    final type = ref.read(createNotifierProvider).requireValue.selectedType;
    return switch (type) {
      ContentType.text => _textTitleControl.value?.isNotEmpty == true || _textBodyControl.value?.isNotEmpty == true,
      ContentType.media => _mediaUrlsControl.value?.isNotEmpty == true,
      ContentType.link => _linkUrlControl.value?.isNotEmpty == true,
    };
  }

  /// Retourne le formulaire actif selon le type sélectionné.
  FormGroup get _activeFormGroup {
    final type = ref.read(createNotifierProvider).requireValue.selectedType;
    return switch (type) {
      ContentType.text => _textFormGroup,
      ContentType.media => _mediaFormGroup,
      ContentType.link => _linkFormGroup,
    };
  }

  @override
  void initState() {
    super.initState();
    _formSubscriptions = [
      _textFormGroup.valueChanges.listen((_) => _formChangeTicker.value++),
      _mediaFormGroup.valueChanges.listen((_) => _formChangeTicker.value++),
      _linkFormGroup.valueChanges.listen((_) => _formChangeTicker.value++),
    ];
    ref.listenManual(createNotifierProvider, (previous, next) {
      final createState = next.value;
      if (_isAnonymousDefaultApplied || createState == null) return;
      _isAnonymousControl.value = createState.isAnonymousByDefault;
      _isAnonymousDefaultApplied = true;
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    for (final sub in _formSubscriptions) {
      sub.cancel();
    }
    _formChangeTicker.dispose();
    _textFormGroup.dispose();
    _mediaFormGroup.dispose();
    _linkFormGroup.dispose();
    _tagsControl.dispose();
    _flairControl.dispose();
    _isAnonymousControl.dispose();
    super.dispose();
  }

  /// Identifiant d'auteur à porter par le contenu créé.
  ///
  /// [anonymousSignatureId] si la case « publier en anonyme » est cochée : le
  /// contenu sera affiché avec le profil anonyme commun. Sinon, l'utilisateur
  /// du téléphone ([localSignatureId]), dont le profil configuré dans les options
  /// sera affiché.
  String get _authorId {
    return _isAnonymousControl.value == true ? anonymousSignatureId : localSignatureId;
  }

  /// Sélectionne le type de contenu.
  ///
  /// - [type] : type de contenu choisi.
  void _onTypeSelected(ContentType type) {
    ref.read(createNotifierProvider.notifier).setType(type);
  }

  /// Valide le formulaire actif, publie le contenu, puis ouvre son détail ou affiche l'erreur.
  ///
  /// La préparation (aperçu d'un lien) et
  /// l'enregistrement sont confiés à [PublishContentNotifier] : la page
  /// affiche son écran de chargement pendant tout ce temps.
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
    if (!_activeFormGroup.valid) {
      _activeFormGroup.markAllAsTouched();
      return;
    }
    final flair = _flairControl.value!.toFlair()!;

    final result = await switch (type) {
      ContentType.text => ref.read(publishContentNotifierProvider.notifier).publish(_buildTextContent(flair)),
      ContentType.media => ref.read(publishContentNotifierProvider.notifier).publish(_buildMediaContent(flair)),
      ContentType.link =>
        ref
            .read(publishContentNotifierProvider.notifier)
            .publishLink(
              url: _linkUrlControl.value!.trim(),
              buildContent: (ogMetadata) => _buildLinkContent(flair, ogMetadata),
            ),
    };
    if (!mounted) {
      return;
    }
    final savedContent = result.right;
    if (savedContent == null) {
      AppSnackbar.showError(context, result.left!);
      return;
    }
    AppSnackbar.showSuccess(context, AppLocalizations.of(context)!.createSuccessMessage);
    // Remplace la page de création par le détail du contenu créé : un retour
    // ramène alors directement à la page d'où la création a été lancée.
    context.pushReplacement(contentDetailPath, extra: savedContent);
  }

  /// Construit le contenu texte saisi.
  ///
  /// - [flair] : flair normalisé du contenu.
  TextContent _buildTextContent(String flair) {
    return TextContent(
      id: UuidX.generate(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      authorId: _authorId,
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
    );
  }

  /// Construit le contenu média saisi.
  ///
  /// - [flair] : flair normalisé du contenu.
  MediaContent _buildMediaContent(String flair) {
    return MediaContent(
      id: UuidX.generate(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      authorId: _authorId,
      senderId: 'local',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      // Placeholder : SaveContentUsecase détermine et corrige le poids réel
      // avant persistance.
      sizeInBytes: 0,
      media: [for (final url in _mediaUrlsControl.value!) ref.read(mediaKindServiceProvider).mediaOf(url)],
      title: _mediaTitleControl.value!,
      body: _mediaBodyControl.value?.isEmpty == true ? null : _mediaBodyControl.value,
      flair: flair,
      tags: _tagsControl.value ?? const [],
    );
  }

  /// Construit le contenu lien saisi, enrichi de l'aperçu lu sur le réseau.
  ///
  /// - [flair] : flair normalisé du contenu.
  /// - [ogMetadata] : aperçu (Open Graph) du lien.
  LinkContent _buildLinkContent(String flair, OgMetadata ogMetadata) {
    return LinkContent(
      id: UuidX.generate(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      authorId: _authorId,
      senderId: 'local',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 0,
      title: _linkTitleControl.value!,
      url: _linkUrlControl.value!.trim(),
      ogImageUrl: ogMetadata.imageUrl,
      ogTitle: ogMetadata.title,
      ogDescription: ogMetadata.description,
      flair: flair,
      tags: _tagsControl.value ?? const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final createWatcher = ref.watch(createNotifierProvider);
    final publishContentNotifierWatcher = ref.watch(publishContentNotifierProvider);

    return createWatcher.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (createState) {
        return Stack(
          children: [
            _buildContent(context, l10n, createState, isPublishing: publishContentNotifierWatcher.isLoading),
            // Page de chargement par-dessus le formulaire, qui reste intact
            // derrière pour être retrouvé tel quel en cas d'échec.
            if (publishContentNotifierWatcher.isLoading) Positioned.fill(child: _buildPublishingPage(l10n)),
          ],
        );
      },
    );
  }

  /// Construit le contenu principal de la page.
  ///
  /// - [isPublishing] : `true` pendant la publication, pour désactiver le bouton de publication.
  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    CreateState createState, {
    required bool isPublishing,
  }) {
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
                  AppGradientButton(isLoading: isPublishing, onTap: _onSave, child: Text(l10n.createSaveButton)),
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
                    onTypeSelected: _onTypeSelected,
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
                      prefixText: AppPrefixes.flair,
                      prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(l10n.createTagsLabel),
                  TagSelector(control: _tagsControl),
                  ReactiveCheckboxListTile(
                    formControl: _isAnonymousControl,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.createAnonymousLabel),
                    subtitle: Text(l10n.createAnonymousDescription),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                child: switch (createState.selectedType) {
                  ContentType.text => TextContentForm(titleControl: _textTitleControl, bodyControl: _textBodyControl),
                  ContentType.media => MediaContentForm(
                    mediaUrlsControl: _mediaUrlsControl,
                    titleControl: _mediaTitleControl,
                    bodyControl: _mediaBodyControl,
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

  /// Page de chargement affichée pendant la publication, qui peut durer quelques secondes le temps de lire l'aperçu d'un lien.
  ///
  /// - [l10n] : traductions de la page.
  Widget _buildPublishingPage(AppLocalizations l10n) {
    // Un Material plutôt qu'une simple couleur de fond : posée par-dessus le
    // Scaffold, la page n'hériterait sinon d'aucun style de texte (texte
    // souligné en jaune, couleur par défaut).
    return Material(
      color: AppColors.background,
      textStyle: const TextStyle(fontSize: 16, color: AppColors.onLight),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const CircularProgressIndicator(),
            // Le texte animé tient sur une ligne : réduit plutôt que de déborder
            // si la place manque (petit écran, police agrandie).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppLoadingText(text: l10n.createPublishingText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
