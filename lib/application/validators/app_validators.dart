import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:bedbug/features/content/domain/extensions/reaction_text_extension.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/features/signature/domain/extensions/signature_text_extension.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Validators personnalisés compatibles avec [ReactiveForm].
///
/// Chaque validator est une instance `const` d'une classe étendant
/// [Validator<dynamic>], à passer dans la liste `validators` d'un
/// [FormControl]. Appliqués au niveau du [FormControl], pas du widget.
class AppValidators {
  AppValidators._();

  /// Vérifie que le champ n'est pas vide ou nul.
  ///
  /// Une liste vide (ex. aucune image choisie) est considérée comme vide.
  static const required = _RequiredValidator();

  /// Vérifie que la valeur correspond au format d'une adresse email.
  ///
  /// Retourne `null` si vide — déléguer la vérification à [required].
  static const email = _EmailValidator();

  /// Vérifie que le mot de passe contient au moins 6 caractères.
  ///
  /// Retourne `null` si vide — déléguer la vérification à [required].
  static const password = _PasswordValidator();

  /// Vérifie que la valeur ne contient aucun chiffre.
  ///
  /// Retourne `null` si vide — déléguer la vérification à [required].
  static const noDigits = _NoDigitsValidator();

  /// Vérifie que la valeur est un nombre décimal valide.
  ///
  /// Accepte `.` ou `,` comme séparateur. Retourne `null` si vide.
  static const decimal = _DecimalValidator();

  /// Vérifie que la valeur décimale est positive ou nulle.
  ///
  /// Retourne `null` si non parseable — déléguer à [decimal].
  static const notNegative = _NotNegativeValidator();

  /// Vérifie qu'il reste un flair exploitable une fois la saisie normalisée.
  ///
  /// Plus strict que [required] : une saisie réduite à `/` ou à des espaces
  /// est refusée, car elle ne produirait aucun flair après normalisation.
  static const flair = _FlairValidator();

  /// Vérifie que le pseudo ne contient que des lettres non accentuées et des tirets, sur 3 caractères minimum.
  ///
  /// Applique la règle du domaine (`isValidPseudo`). Retourne `null` si vide
  /// — déléguer la vérification à [required].
  static const pseudo = _PseudoValidator();

  /// Vérifie que l'icône ne contient aucun mot (pas de suite de lettres).
  ///
  /// Applique la règle du domaine (`isValidAvatarText`). Retourne `null` si
  /// vide — déléguer la vérification à [required].
  static const avatarText = _AvatarTextValidator();

  /// Vérifie que la description d'une signature tient sur une ligne et ne dépasse pas sa longueur maximale.
  ///
  /// Applique la règle du domaine (`isValidSignatureBio`). Retourne `null`
  /// si vide : la description est optionnelle.
  static const signatureBio = _SignatureBioValidator();

  /// Vérifie que la bulle d'une réaction tient sur une ligne et ne dépasse pas sa longueur maximale.
  ///
  /// Applique la règle du domaine (`isValidReactionBubble`). Retourne `null`
  /// si vide : la bulle est optionnelle.
  static const reactionBubble = _ReactionBubbleValidator();

  /// Validator de [FormGroup] vérifiant que l'identifiant saisi est valide sur le réseau choisi.
  ///
  /// L'identifiant dépend du réseau (format Twitter, Twitch, GitHub…, URL
  /// collée qui doit pointer vers ce réseau) : la vérification se fait donc
  /// au niveau du groupe, et l'erreur `socialHandle` est posée sur le
  /// contrôle de l'identifiant, comme le fait `Validators.mustMatch`. Sans
  /// effet tant que le réseau n'est pas choisi ou l'identifiant vide —
  /// déléguer ces cas à [required].
  ///
  /// - [networkControlName] : nom du contrôle portant le `SocialNetwork` choisi.
  /// - [handleControlName] : nom du contrôle portant l'identifiant saisi.
  static Validator<dynamic> socialHandle(String networkControlName, String handleControlName) {
    return _SocialHandleValidator(networkControlName, handleControlName);
  }
}

class _RequiredValidator extends Validator<dynamic> {
  const _RequiredValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value == null) return {'required': true};
    if (value is String && value.trim().isEmpty) return {'required': true};
    if (value is Iterable<dynamic> && value.isEmpty) return {'required': true};
    return null;
  }
}

class _EmailValidator extends Validator<dynamic> {
  const _EmailValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return {'email': true};
    }
    return null;
  }
}

class _PasswordValidator extends Validator<dynamic> {
  const _PasswordValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    if (value.length < 6) return {'minLength': true};
    return null;
  }
}

class _NoDigitsValidator extends Validator<dynamic> {
  const _NoDigitsValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    if (RegExp(r'\d').hasMatch(value)) return {'noDigits': true};
    return null;
  }
}

class _DecimalValidator extends Validator<dynamic> {
  const _DecimalValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    if (!RegExp(r'^\d+([.,]\d+)?$').hasMatch(value.trim())) {
      return {'decimal': true};
    }
    return null;
  }
}

class _NotNegativeValidator extends Validator<dynamic> {
  const _NotNegativeValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed != null && parsed < 0) return {'notNegative': true};
    return null;
  }
}

class _FlairValidator extends Validator<dynamic> {
  const _FlairValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.toFlair() == null) return {'required': true};
    return null;
  }
}

class _PseudoValidator extends Validator<dynamic> {
  const _PseudoValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!value.trim().isValidPseudo) {
      return {'pseudo': true};
    }
    return null;
  }
}

class _SignatureBioValidator extends Validator<dynamic> {
  const _SignatureBioValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!value.trim().isValidSignatureBio) {
      return {'signatureBio': true};
    }
    return null;
  }
}

class _ReactionBubbleValidator extends Validator<dynamic> {
  const _ReactionBubbleValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!value.trim().isValidReactionBubble) {
      return {'reactionBubble': true};
    }
    return null;
  }
}

class _AvatarTextValidator extends Validator<dynamic> {
  const _AvatarTextValidator() : super();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!value.isValidAvatarText) {
      return {'avatarText': true};
    }
    return null;
  }
}

class _SocialHandleValidator extends Validator<dynamic> {
  const _SocialHandleValidator(this.networkControlName, this.handleControlName) : super();

  final String networkControlName;

  final String handleControlName;

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    if (control is! FormGroup) {
      return null;
    }
    final network = control.control(networkControlName).value;
    final handleControl = control.control(handleControlName);
    final handle = handleControl.value;

    if (network is! SocialNetwork || handle is! String || handle.trim().isEmpty) {
      handleControl.removeError('socialHandle');
      return null;
    }
    if (network.normalizeHandle(handle) == null) {
      const error = {'socialHandle': true};
      handleControl.setErrors(error, markAsDirty: false);
      return error;
    }
    handleControl.removeError('socialHandle');
    return null;
  }
}
