import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:bedbug/features/content/domain/gateways/exchange_codec_gateway.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_bundle.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_offer.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_request.dart';
import 'package:bedbug/features/content/infrastructure/models/drawing_binary_codec.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Version du format d'échange. À incrémenter à chaque changement incompatible.
const int exchangeFormatVersion = 1;

/// Taille maximale d'un message une fois décompressé, en octets.
///
/// Un message compressé de quelques kilo-octets peut se décompresser en plusieurs giga-octets (« zip bomb ») :
/// la décompression s'arrête net au-delà de cette taille, bien au-dessus d'un lot légitime.
const int maxDecompressedExchangeBytes = 4 * 1024 * 1024;

/// Provider du [JsonZlibExchangeCodecGateway].
final exchangeCodecGatewayProvider = Provider<ExchangeCodecGateway>((ref) => const JsonZlibExchangeCodecGateway());

/// Implémentation de [ExchangeCodecGateway] : JSON compressé en zlib.
///
/// Le JSON garde le format lisible et facile à faire évoluer (champs optionnels, version) ; zlib, présent dans la
/// bibliothèque standard de Dart, compresse très bien le texte et les clés JSON répétées. Chaque message est un
/// objet `{"version": 1, ...}` compressé d'un bloc. Les dessins voyagent dans leur encodage binaire compact
/// ([DrawingBinaryCodec]), en base64.
///
/// Le décodage vérifie le type de chaque champ et lève une [DataException] au premier écart.
class JsonZlibExchangeCodecGateway implements ExchangeCodecGateway {
  /// Crée un [JsonZlibExchangeCodecGateway].
  const JsonZlibExchangeCodecGateway();

  /// Encodage binaire des dessins.
  static const DrawingBinaryCodec _drawingCodec = DrawingBinaryCodec();

  @override
  Uint8List encodeOffer(ExchangeOffer offer) {
    return _compress({
      'contents': [
        for (final content in offer.contents)
          {
            'id': content.id,
            'size': content.sizeInBytes,
            'reactionCount': content.reactionCount,
            if (content.latestReactionAt != null) 'latestReactionAt': content.latestReactionAt!.millisecondsSinceEpoch,
          },
      ],
    });
  }

  @override
  ExchangeOffer decodeOffer(Uint8List bytes) {
    final json = _decompress(bytes);
    return ExchangeOffer(
      contents: _readList(json, 'contents').map((item) {
        final map = _asMap(item);
        return OfferedContent(
          id: _readString(map, 'id'),
          sizeInBytes: _readInt(map, 'size'),
          reactionCount: _readInt(map, 'reactionCount'),
          latestReactionAt: _readOptionalDate(map, 'latestReactionAt'),
        );
      }).toList(),
    );
  }

  @override
  Uint8List encodeRequest(ExchangeRequest request) {
    return _compress({'contentIds': request.contentIds, 'reactionContentIds': request.reactionContentIds});
  }

  @override
  ExchangeRequest decodeRequest(Uint8List bytes) {
    final json = _decompress(bytes);
    return ExchangeRequest(
      contentIds: _readList(json, 'contentIds').map(_asString).toList(),
      reactionContentIds: _readList(json, 'reactionContentIds').map(_asString).toList(),
    );
  }

  @override
  Uint8List encodeBundle(ExchangeBundle bundle) {
    return _compress({
      'contents': [for (final exchanged in bundle.contents) _contentToJson(exchanged)],
      'reactions': [for (final reaction in bundle.reactions) _reactionToJson(reaction)],
    });
  }

  @override
  ExchangeBundle decodeBundle(Uint8List bytes) {
    final json = _decompress(bytes);
    return ExchangeBundle(
      contents: _readList(json, 'contents').map((item) => _contentFromJson(_asMap(item))).toList(),
      reactions: _readList(json, 'reactions').map((item) => _reactionFromJson(_asMap(item))).toList(),
    );
  }

  /// Retourne [json], complété de la version du format, sérialisé puis compressé.
  ///
  /// - [json] : contenu du message.
  Uint8List _compress(Map<String, Object?> json) {
    final bytes = utf8.encode(jsonEncode({'version': exchangeFormatVersion, ...json}));
    return Uint8List.fromList(ZLibEncoder(level: ZLibOption.maxLevel).convert(bytes));
  }

  /// Retourne le message décompressé et décodé depuis [bytes], après avoir vérifié sa version.
  ///
  /// La décompression se fait par morceaux et s'interrompt dès que [maxDecompressedExchangeBytes] est dépassé.
  ///
  /// - [bytes] : message reçu.
  Map<String, Object?> _decompress(Uint8List bytes) {
    final output = _LimitedBytesSink(maxDecompressedExchangeBytes);
    try {
      final input = ZLibDecoder().startChunkedConversion(output);
      input.add(bytes);
      input.close();
    } on DataException {
      rethrow;
    } on FormatException catch (error) {
      throw DataException('JsonZlibExchangeCodecGateway', error);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(output.bytes));
    } on FormatException catch (error) {
      throw DataException('JsonZlibExchangeCodecGateway', error);
    }
    final json = _asMap(decoded);
    final version = _readInt(json, 'version');
    if (version != exchangeFormatVersion) {
      throw DataException('JsonZlibExchangeCodecGateway', 'version de format inconnue : $version');
    }
    return json;
  }

  /// Retourne [exchanged] au format JSON, sans aucun champ propre à l'appareil.
  ///
  /// Ni l'auteur, ni la provenance, ni les scores, ni le poids ne voyagent : seuls les champs publics du contenu,
  /// sa date, son nombre de rebonds et la signature de son auteur.
  ///
  /// - [exchanged] : contenu à encoder, avec sa signature.
  Map<String, Object?> _contentToJson(ExchangedContent exchanged) {
    final content = exchanged.content;
    final signature = exchanged.signature;
    return {
      'id': content.id,
      'createdAt': content.createdAt.millisecondsSinceEpoch,
      'updatedAt': content.updatedAt.millisecondsSinceEpoch,
      'bounce': content.bounce,
      'flair': content.flair,
      'tags': [for (final tag in content.tags) tag.value],
      if (signature != null) 'signature': _signatureToJson(signature),
      ...switch (content) {
        TextContent() => {'type': ContentType.text.value, 'title': content.title, 'body': content.body},
        LinkContent() => {
          'type': ContentType.link.value,
          'title': content.title,
          'body': content.body,
          'url': content.url,
          'ogImageUrl': content.ogImageUrl,
          'ogTitle': content.ogTitle,
          'ogDescription': content.ogDescription,
        },
        MediaContent() => {
          'type': ContentType.media.value,
          'title': content.title,
          'body': content.body,
          'media': [
            for (final media in content.media) {'url': media.url, 'kind': media.kind.value},
          ],
        },
        DrawingContent() => {
          'type': ContentType.drawing.value,
          'title': content.title,
          'drawing': base64Encode(_drawingCodec.encode(content.drawing)),
        },
        _ => throw DataException('JsonZlibExchangeCodecGateway', 'type de contenu inconnu : ${content.runtimeType}'),
      },
    };
  }

  /// Retourne le contenu décodé depuis [json].
  ///
  /// Les champs propres à l'appareil reçoivent des valeurs neutres (contenu public, scores à `1`, auteur vide,
  /// poids nul) : c'est au use case d'import de les fixer.
  ///
  /// - [json] : contenu reçu.
  ExchangedContent _contentFromJson(Map<String, Object?> json) {
    final id = _readString(json, 'id');
    final createdAt = _readDate(json, 'createdAt');
    final updatedAt = _readDate(json, 'updatedAt');
    final bounce = _readInt(json, 'bounce');
    final flair = _readString(json, 'flair');
    final tags = _readList(json, 'tags').map(_asInt).map(_tagFromValue).whereType<Tag>().toSet().toList();
    final title = _readString(json, 'title');
    final signatureJson = json['signature'];
    final signature = signatureJson == null ? null : _signatureFromJson(_asMap(signatureJson));

    final type = _readInt(json, 'type');
    final Content content;
    if (type == ContentType.text.value) {
      content = TextContent(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        signatureId: '',
        origin: ContentOrigin.public,
        broadcastScore: 1,
        survivalScore: 1,
        displayScore: 1,
        bounce: bounce,
        sizeInBytes: 0,
        flair: flair,
        tags: tags,
        title: title,
        body: _readString(json, 'body'),
      );
      return ExchangedContent(content: content, signature: signature);
    }
    if (type == ContentType.link.value) {
      content = LinkContent(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        signatureId: '',
        origin: ContentOrigin.public,
        broadcastScore: 1,
        survivalScore: 1,
        displayScore: 1,
        bounce: bounce,
        sizeInBytes: 0,
        flair: flair,
        tags: tags,
        title: title,
        body: _readOptionalString(json, 'body'),
        url: _readString(json, 'url'),
        ogImageUrl: _readOptionalString(json, 'ogImageUrl'),
        ogTitle: _readOptionalString(json, 'ogTitle'),
        ogDescription: _readOptionalString(json, 'ogDescription'),
      );
      return ExchangedContent(content: content, signature: signature);
    }
    if (type == ContentType.media.value) {
      content = MediaContent(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        signatureId: '',
        origin: ContentOrigin.public,
        broadcastScore: 1,
        survivalScore: 1,
        displayScore: 1,
        bounce: bounce,
        sizeInBytes: 0,
        flair: flair,
        tags: tags,
        title: title,
        body: _readOptionalString(json, 'body'),
        media: _readList(json, 'media').map((item) {
          final map = _asMap(item);
          return ContentMedia(url: _readString(map, 'url'), kind: MediaKind.fromValue(_readInt(map, 'kind')));
        }).toList(),
      );
      return ExchangedContent(content: content, signature: signature);
    }
    if (type == ContentType.drawing.value) {
      final Uint8List drawingBytes;
      try {
        drawingBytes = base64Decode(_readString(json, 'drawing'));
      } on FormatException catch (error) {
        throw DataException('JsonZlibExchangeCodecGateway', error);
      }
      try {
        content = DrawingContent(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          signatureId: '',
          origin: ContentOrigin.public,
          broadcastScore: 1,
          survivalScore: 1,
          displayScore: 1,
          bounce: bounce,
          sizeInBytes: 0,
          flair: flair,
          tags: tags,
          title: title,
          drawing: _drawingCodec.decode(drawingBytes),
        );
      } on FormatException catch (error) {
        throw DataException('JsonZlibExchangeCodecGateway', error);
      }
      return ExchangedContent(content: content, signature: signature);
    }
    throw DataException('JsonZlibExchangeCodecGateway', 'type de contenu inconnu : $type');
  }

  /// Retourne [signature] au format JSON, sans son identifiant : le destinataire en déduit le sien.
  ///
  /// - [signature] : signature de l'auteur d'un contenu.
  Map<String, Object?> _signatureToJson(Signature signature) {
    return {
      'pseudo': signature.pseudo,
      'avatarText': signature.avatarText,
      'colorArgb': signature.colorArgb,
      'ghostSpeed': signature.ghostSpeed,
      'bio': signature.bio,
      'bioFont': signature.bioFont.value,
      'socialLinks': {for (final entry in signature.socialLinks.entries) '${entry.key.value}': entry.value},
    };
  }

  /// Retourne la signature décodée depuis [json], avec un identifiant et des dates vides, fixés à l'import.
  ///
  /// Les réseaux inconnus de cette version de l'app sont ignorés.
  ///
  /// - [json] : signature reçue.
  Signature _signatureFromJson(Map<String, Object?> json) {
    final socialLinks = <SocialNetwork, String>{};
    final rawLinks = json['socialLinks'];
    if (rawLinks != null) {
      for (final entry in _asMap(rawLinks).entries) {
        final network = SocialNetwork.fromValue(int.tryParse(entry.key) ?? -1);
        if (network != null) {
          socialLinks[network] = _asString(entry.value);
        }
      }
    }
    return Signature(
      id: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      pseudo: _readString(json, 'pseudo'),
      avatarText: _readString(json, 'avatarText'),
      colorArgb: _readOptionalInt(json, 'colorArgb'),
      ghostSpeed: _readDouble(json, 'ghostSpeed'),
      bio: _readOptionalString(json, 'bio'),
      bioFont: TextFont.fromValue(_readInt(json, 'bioFont')),
      socialLinks: socialLinks,
    );
  }

  /// Retourne [reaction] au format JSON, sans son auteur.
  ///
  /// - [reaction] : réaction à encoder.
  Map<String, Object?> _reactionToJson(Reaction reaction) {
    return {
      'id': reaction.id,
      'contentId': reaction.contentId,
      'createdAt': reaction.createdAt.millisecondsSinceEpoch,
      'updatedAt': reaction.updatedAt.millisecondsSinceEpoch,
      'avatarText': reaction.avatarText,
      'bubbleText': reaction.bubbleText,
      'colorArgb': reaction.colorArgb,
      'ghostSpeed': reaction.ghostSpeed,
      'bubbleFont': reaction.bubbleFont.value,
    };
  }

  /// Retourne la réaction décodée depuis [json], avec un auteur vide, fixé à l'import.
  ///
  /// - [json] : réaction reçue.
  Reaction _reactionFromJson(Map<String, Object?> json) {
    return Reaction(
      id: _readString(json, 'id'),
      createdAt: _readDate(json, 'createdAt'),
      updatedAt: _readDate(json, 'updatedAt'),
      contentId: _readString(json, 'contentId'),
      authorId: '',
      avatarText: _readString(json, 'avatarText'),
      bubbleText: _readString(json, 'bubbleText'),
      colorArgb: _readOptionalInt(json, 'colorArgb'),
      ghostSpeed: _readDouble(json, 'ghostSpeed'),
      bubbleFont: TextFont.fromValue(_readInt(json, 'bubbleFont')),
    );
  }

  /// Retourne le tag de valeur [value], ou `null` s'il est inconnu de cette version de l'app.
  ///
  /// - [value] : valeur persistée du tag.
  Tag? _tagFromValue(int value) {
    for (final tag in Tag.values) {
      if (tag.value == value) {
        return tag;
      }
    }
    return null;
  }

  /// Retourne [value] en objet JSON, ou lève une [DataException].
  ///
  /// - [value] : valeur décodée.
  Map<String, Object?> _asMap(Object? value) {
    if (value is! Map<String, Object?>) {
      throw DataException('JsonZlibExchangeCodecGateway', 'objet attendu, reçu ${value.runtimeType}');
    }
    return value;
  }

  /// Retourne [value] en texte, ou lève une [DataException].
  ///
  /// - [value] : valeur décodée.
  String _asString(Object? value) {
    if (value is! String) {
      throw DataException('JsonZlibExchangeCodecGateway', 'texte attendu, reçu ${value.runtimeType}');
    }
    return value;
  }

  /// Retourne [value] en entier, ou lève une [DataException].
  ///
  /// - [value] : valeur décodée.
  int _asInt(Object? value) {
    if (value is! int) {
      throw DataException('JsonZlibExchangeCodecGateway', 'entier attendu, reçu ${value.runtimeType}');
    }
    return value;
  }

  /// Retourne la liste [key] de [json], ou lève une [DataException].
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  List<Object?> _readList(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List<Object?>) {
      throw DataException('JsonZlibExchangeCodecGateway', 'liste attendue pour "$key"');
    }
    return value;
  }

  /// Retourne le texte [key] de [json], ou lève une [DataException].
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  String _readString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw DataException('JsonZlibExchangeCodecGateway', 'texte attendu pour "$key"');
    }
    return value;
  }

  /// Retourne le texte [key] de [json], `null` s'il est absent, ou lève une [DataException].
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  String? _readOptionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value != null && value is! String) {
      throw DataException('JsonZlibExchangeCodecGateway', 'texte attendu pour "$key"');
    }
    return value as String?;
  }

  /// Retourne l'entier [key] de [json], ou lève une [DataException].
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  int _readInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw DataException('JsonZlibExchangeCodecGateway', 'entier attendu pour "$key"');
    }
    return value;
  }

  /// Retourne l'entier [key] de [json], `null` s'il est absent, ou lève une [DataException].
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  int? _readOptionalInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value != null && value is! int) {
      throw DataException('JsonZlibExchangeCodecGateway', 'entier attendu pour "$key"');
    }
    return value as int?;
  }

  /// Retourne le nombre [key] de [json], ou lève une [DataException].
  ///
  /// JSON ne distingue pas `1` de `1.0` : un entier est accepté.
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  double _readDouble(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! num || !value.isFinite) {
      throw DataException('JsonZlibExchangeCodecGateway', 'nombre attendu pour "$key"');
    }
    return value.toDouble();
  }

  /// Retourne la date [key] de [json], encodée en millisecondes, ou lève une [DataException].
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  DateTime _readDate(Map<String, Object?> json, String key) {
    final date = _readOptionalDate(json, key);
    if (date == null) {
      throw DataException('JsonZlibExchangeCodecGateway', 'date attendue pour "$key"');
    }
    return date;
  }

  /// Retourne la date [key] de [json], `null` si elle est absente, ou lève une [DataException].
  ///
  /// Une date hors de la plage représentable par [DateTime] est refusée.
  ///
  /// - [json] : objet lu.
  /// - [key] : clé du champ.
  DateTime? _readOptionalDate(Map<String, Object?> json, String key) {
    final millis = _readOptionalInt(json, key);
    if (millis == null) {
      return null;
    }
    if (millis.abs() > _maxDateMillis) {
      throw DataException('JsonZlibExchangeCodecGateway', 'date hors limites pour "$key"');
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}

/// Plus grande date représentable par [DateTime], en millisecondes : 100 000 000 jours autour de 1970.
const int _maxDateMillis = 8640000000000000;

/// Réceptacle d'octets qui refuse d'accumuler plus de [maxBytes] octets.
///
/// Branché en sortie du décompresseur, il interrompt une décompression qui gonfle anormalement avant qu'elle
/// n'occupe toute la mémoire.
class _LimitedBytesSink implements Sink<List<int>> {
  /// Crée un [_LimitedBytesSink].
  ///
  /// - [maxBytes] : nombre maximal d'octets acceptés.
  _LimitedBytesSink(this.maxBytes);

  /// Nombre maximal d'octets acceptés.
  final int maxBytes;

  /// Octets accumulés.
  final BytesBuilder _builder = BytesBuilder(copy: false);

  /// Octets accumulés jusqu'ici.
  Uint8List get bytes {
    return _builder.toBytes();
  }

  @override
  void add(List<int> data) {
    if (_builder.length + data.length > maxBytes) {
      throw DataException('JsonZlibExchangeCodecGateway', 'message décompressé au-delà de $maxBytes octets');
    }
    _builder.add(data);
  }

  @override
  void close() {}
}
