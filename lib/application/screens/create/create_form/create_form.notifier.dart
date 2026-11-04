import 'package:bedbug/application/screens/create/create_publishing/create_publishing.notifier.dart';
import 'package:bedbug/application/validators/flair.validator.dart';
import 'package:bedbug/application/validators/not_empty.validator.dart';
import 'package:bedbug/application/validators/safe_url.validator.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/extensions/string_uuid_x.dart';
import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.gateway.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/content.extension.dart';
import 'package:bedbug/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/resources/content/content/content_type.enum.dart';
import 'package:bedbug/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/resources/content/content/link_content.entity.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:bedbug/resources/content/content/text_content.entity.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Provider du [CreateFormNotifier].
///
/// `autoDispose` : le formulaire repart de zéro à chaque ouverture de la page, ce qui relit aussi le réglage
/// « anonyme par défaut » s'il a changé entre-temps.
final createFormNotifierProvider = AsyncNotifierProvider.autoDispose<CreateFormNotifier, void>(CreateFormNotifier.new);

/// Notifier portant le formulaire de création de contenu : ses contrôles, ses règles et sa publication.
///
/// Le formulaire vit ici plutôt que dans un widget : le sélecteur de type, les champs de chaque type et le bouton de
/// publication sont des widgets séparés qui lisent chacun leurs contrôles ici, sans se les passer en paramètre. Son
/// état ne porte que le chargement des réglages : les widgets réagissent aux contrôles eux-mêmes. Le widget qui
/// l'observe le garde en vie tant que le formulaire est affiché.
class CreateFormNotifier extends AsyncNotifier<void> {
  /// Cas d'usage de lecture des réglages, pour la publication anonyme par défaut.
  late final _getSettingsUsecase = ref.read(getSettingsUsecaseProvider);

  /// Contrôle du type de contenu choisi.
  late FormControl<ContentType> typeControl;

  /// Contrôle du titre d'un [TextContent].
  late FormControl<String> textTitleControl;

  /// Contrôle du corps d'un [TextContent].
  late FormControl<String> textBodyControl;

  /// Formulaire d'un [TextContent].
  late FormGroup textForm;

  /// Contrôle des adresses des médias d'un [MediaContent], dans l'ordre d'affichage.
  late FormControl<List<String>> mediaUrlsControl;

  /// Contrôle de l'adresse de média en cours de saisie, avant son ajout à [mediaUrlsControl].
  ///
  /// Hors de [mediaForm] : une adresse en cours de saisie ne doit pas bloquer la publication.
  late FormControl<String> mediaUrlInputControl;

  /// Contrôle du titre d'un [MediaContent].
  late FormControl<String> mediaTitleControl;

  /// Contrôle de la description optionnelle d'un [MediaContent].
  late FormControl<String> mediaBodyControl;

  /// Formulaire d'un [MediaContent].
  late FormGroup mediaForm;

  /// Contrôle du dessin d'un [DrawingContent], `null` tant que rien n'a été dessiné.
  late FormControl<Drawing> drawingControl;

  /// Contrôle du titre d'un [DrawingContent].
  late FormControl<String> drawingTitleControl;

  /// Formulaire d'un [DrawingContent].
  late FormGroup drawingForm;

  /// Contrôle du titre d'un [LinkContent].
  late FormControl<String> linkTitleControl;

  /// Contrôle de l'URL d'un [LinkContent].
  late FormControl<String> linkUrlControl;

  /// Formulaire d'un [LinkContent].
  late FormGroup linkForm;

  /// Contrôle des tags sélectionnés, commun à tous les types de contenu.
  late FormControl<List<Tag>> tagsControl;

  /// Contrôle du flair libre (ex. `france`), commun à tous les types de contenu.
  late FormControl<String> flairControl;

  /// Contrôle « publier en anonyme », commun à tous les types de contenu.
  late FormControl<bool> isAnonymousControl;

  /// Formulaire complet de la page, qui regroupe tous les contrôles.
  ///
  /// Sert à écouter n'importe quel changement de la page en un seul endroit, et à tout disposer d'un coup. Sa validité
  /// n'a pas de sens : elle inclut les formulaires des types non choisis. Voir [isPublishable].
  late FormGroup form;

  @override
  Future<void> build() async {
    typeControl = FormControl<ContentType>(value: ContentType.text);
    textTitleControl = FormControl<String>(validators: [const NotEmptyValidator()]);
    textBodyControl = FormControl<String>(validators: [const NotEmptyValidator()]);
    textForm = FormGroup({'title': textTitleControl, 'body': textBodyControl});
    mediaUrlsControl = FormControl<List<String>>(value: const [], validators: [const NotEmptyValidator()]);
    mediaUrlInputControl = FormControl<String>(validators: [const SafeUrlValidator()]);
    mediaTitleControl = FormControl<String>(validators: [const NotEmptyValidator()]);
    mediaBodyControl = FormControl<String>();
    mediaForm = FormGroup({'media': mediaUrlsControl, 'title': mediaTitleControl, 'body': mediaBodyControl});
    drawingControl = FormControl<Drawing>(validators: [const NotEmptyValidator()]);
    drawingTitleControl = FormControl<String>(validators: [const NotEmptyValidator()]);
    drawingForm = FormGroup({'drawing': drawingControl, 'title': drawingTitleControl});
    linkTitleControl = FormControl<String>(validators: [const NotEmptyValidator()]);
    linkUrlControl = FormControl<String>(validators: [const NotEmptyValidator(), const SafeUrlValidator()]);
    linkForm = FormGroup({'title': linkTitleControl, 'url': linkUrlControl});
    tagsControl = FormControl<List<Tag>>(value: const []);
    flairControl = FormControl<String>(validators: [const FlairValidator()]);
    isAnonymousControl = FormControl<bool>(value: false);
    form = FormGroup({
      'type': typeControl,
      'text': textForm,
      'media': mediaForm,
      'mediaUrlInput': mediaUrlInputControl,
      'drawing': drawingForm,
      'link': linkForm,
      'tags': tagsControl,
      'flair': flairControl,
      'isAnonymous': isAnonymousControl,
    });
    ref.onDispose(form.dispose);

    final result = await _getSettingsUsecase(const NoParams());
    if (!ref.mounted) {
      return;
    }
    // Des réglages illisibles ne bloquent pas la création : la case « anonyme » part simplement décochée.
    isAnonymousControl.value = result.right?.isAnonymousByDefault ?? false;
  }

  /// Type de contenu actuellement choisi.
  ContentType get selectedType {
    return typeControl.value ?? ContentType.text;
  }

  /// Formulaire du type de contenu choisi.
  FormGroup get activeForm {
    return switch (selectedType) {
      ContentType.text => textForm,
      ContentType.media => mediaForm,
      ContentType.link => linkForm,
      ContentType.drawing => drawingForm,
    };
  }

  /// `true` si le type ne peut plus être changé, parce que des valeurs ont été saisies pour le type choisi.
  ///
  /// Changer de type ferait perdre de vue ce qui a déjà été saisi : le choix se verrouille dès la première saisie.
  bool get isTypeLocked {
    return switch (selectedType) {
      ContentType.text => textTitleControl.value?.isNotEmpty == true || textBodyControl.value?.isNotEmpty == true,
      ContentType.media => mediaUrlsControl.value?.isNotEmpty == true,
      ContentType.link => linkUrlControl.value?.isNotEmpty == true,
      ContentType.drawing => drawingControl.value != null,
    };
  }

  /// `true` si le contenu peut être publié : le flair, commun à tous les types, et le formulaire du type choisi sont
  /// valides.
  bool get isPublishable {
    return flairControl.valid && activeForm.valid;
  }

  /// Vérifie l'adresse saisie dans [mediaUrlInputControl], l'ajoute à la suite des médias, puis vide le champ.
  ///
  /// Une adresse déjà ajoutée n'est pas dupliquée. Une adresse refusée reste dans le champ, avec son message d'erreur,
  /// pour pouvoir la corriger.
  void addMediaUrl() {
    final url = mediaUrlInputControl.value?.trim() ?? '';
    if (url.isEmpty) {
      return;
    }
    if (!mediaUrlInputControl.valid) {
      mediaUrlInputControl.markAsTouched();
      return;
    }
    final mediaUrls = mediaUrlsControl.value ?? const <String>[];
    if (!mediaUrls.contains(url) && mediaUrls.length < maxMediaPerContent) {
      mediaUrlsControl.value = [...mediaUrls, url];
    }
    mediaUrlInputControl.reset();
  }

  /// Retire le média à la position [index].
  ///
  /// - [index] : position du média dans [mediaUrlsControl].
  void removeMediaUrl(int index) {
    mediaUrlsControl.value = [...?mediaUrlsControl.value]..removeAt(index);
  }

  /// Valide le formulaire du type choisi, construit le contenu et le publie.
  ///
  /// Retourne `null` si le formulaire est invalide (ses erreurs sont alors affichées), sinon le contenu enregistré ou
  /// le message d'erreur à afficher. La publication elle-même, et son écran de chargement, sont confiés au
  /// [CreatePublishingNotifier].
  Future<Either<String, Content>?> publish() async {
    // Le flair est commun à tous les types et hors du formulaire actif : il est validé à part, en marquant aussi le
    // formulaire actif pour afficher toutes les erreurs d'un coup.
    if (!isPublishable) {
      flairControl.markAsTouched();
      activeForm.markAllAsTouched();
      return null;
    }
    final flair = flairControl.value!.toFlair()!;
    final createPublishingNotifier = ref.read(createPublishingNotifierProvider.notifier);
    return switch (selectedType) {
      ContentType.text => createPublishingNotifier.publish(_buildTextContent(flair)),
      ContentType.media => createPublishingNotifier.publish(_buildMediaContent(flair)),
      ContentType.drawing => createPublishingNotifier.publish(_buildDrawingContent(flair)),
      ContentType.link => createPublishingNotifier.publishLink(
        url: linkUrlControl.value!.trim(),
        buildContent: (ogMetadata) => _buildLinkContent(flair, ogMetadata),
      ),
    };
  }

  /// Identifiant de la signature à porter par le contenu créé.
  ///
  /// [anonymousSignatureId] si la case « publier en anonyme » est cochée : le contenu sera affiché avec le profil
  /// anonyme commun. Sinon, l'utilisateur du téléphone ([localSignatureId]), dont le profil configuré dans les options
  /// sera affiché.
  String get _signatureId {
    return isAnonymousControl.value == true ? anonymousSignatureId : localSignatureId;
  }

  /// Construit le contenu texte saisi.
  ///
  /// - [flair] : flair normalisé du contenu.
  TextContent _buildTextContent(String flair) {
    return TextContent(
      id: UuidX.generate(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      signatureId: _signatureId,
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      // Placeholder : SaveContentUsecase détermine et corrige le poids réel
      // avant persistance.
      sizeInBytes: 0,
      title: textTitleControl.value!,
      body: textBodyControl.value!,
      flair: flair,
      tags: tagsControl.value ?? const [],
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
      signatureId: _signatureId,
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      // Placeholder : SaveContentUsecase détermine et corrige le poids réel
      // avant persistance.
      sizeInBytes: 0,
      media: [for (final url in mediaUrlsControl.value!) ContentMedia.fromUrl(url)],
      title: mediaTitleControl.value!,
      body: mediaBodyControl.value?.isEmpty == true ? null : mediaBodyControl.value,
      flair: flair,
      tags: tagsControl.value ?? const [],
    );
  }

  /// Construit le contenu dessiné.
  ///
  /// - [flair] : flair normalisé du contenu.
  DrawingContent _buildDrawingContent(String flair) {
    return DrawingContent(
      id: UuidX.generate(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      signatureId: _signatureId,
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      // Placeholder : SaveContentUsecase détermine et corrige le poids réel
      // avant persistance.
      sizeInBytes: 0,
      drawing: drawingControl.value!,
      title: drawingTitleControl.value!,
      flair: flair,
      tags: tagsControl.value ?? const [],
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
      signatureId: _signatureId,
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 0,
      title: linkTitleControl.value!,
      url: linkUrlControl.value!.trim(),
      ogImageUrl: ogMetadata.imageUrl,
      ogTitle: ogMetadata.title,
      ogDescription: ogMetadata.description,
      flair: flair,
      tags: tagsControl.value ?? const [],
    );
  }
}
