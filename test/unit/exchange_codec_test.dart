import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bedbug/gateways/exchange/exchange_bundle/exchange_bundle.value_object.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.config.dart';
import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.gateway.json_zlib.dart';
import 'package:bedbug/gateways/exchange/exchange_offer/exchange_offer.value_object.dart';
import 'package:bedbug/gateways/exchange/exchange_request/exchange_request.value_object.dart';
import 'package:bedbug/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/resources/content/content/link_content.entity.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:bedbug/resources/content/content/text_content.entity.dart';
import 'package:bedbug/resources/content/content_media/content_media.value_object.dart';
import 'package:bedbug/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Date de référence des contenus de test, à la milliseconde près (précision du format d'échange).
final DateTime _date = DateTime.fromMillisecondsSinceEpoch(1790000000000);

/// Retourne un contenu texte local de test, avec des champs propres à l'appareil qui ne doivent pas voyager.
TextContent _text() {
  return TextContent(
    id: 'text',
    createdAt: _date,
    updatedAt: _date,
    signatureId: 'local',
    origin: ContentOrigin.owned,
    broadcastScore: 0.7,
    survivalScore: 0.6,
    displayScore: 0.5,
    bounce: 3,
    sizeInBytes: 42,
    flair: 'france',
    tags: const [Tag.info, Tag.spoiler],
    title: 'Titre',
    body: 'Corps du texte',
  );
}

/// Retourne un message zlib contenant [json] tel quel, sans passer par le codec.
Uint8List _rawMessage(Object json) {
  return Uint8List.fromList(ZLibEncoder().convert(utf8.encode(jsonEncode(json))));
}

void main() {
  const codec = JsonZlibExchangeCodecGateway();

  test('une offre et une demande survivent à un aller-retour', () {
    final offer = ExchangeOffer(
      contents: [
        const OfferedContent(id: 'a', sizeInBytes: 120, reactionCount: 0),
        OfferedContent(id: 'b', sizeInBytes: 3000, reactionCount: 4, latestReactionAt: _date),
      ],
    );
    const request = ExchangeRequest(contentIds: ['a'], reactionContentIds: ['b']);

    expect(codec.decodeOffer(codec.encodeOffer(offer)), offer);
    expect(codec.decodeRequest(codec.encodeRequest(request)), request);
  });

  test('un lot transporte les champs publics de chaque type de contenu, sans les champs propres à l\'appareil', () {
    const drawing = Drawing(
      palette: defaultDrawingPalette,
      operations: [
        DrawingStroke(
          layer: 1,
          colorIndex: 2,
          brush: DrawingBrush.pen,
          size: 1,
          seed: 7,
          points: [DrawingPoint(10, 10), DrawingPoint(20, 12)],
        ),
      ],
    );
    final signature = Signature(
      id: 'local',
      createdAt: _date,
      updatedAt: _date,
      pseudo: 'bedbug',
      avatarText: '(◕‿◕)',
      colorArgb: 0xFF112233,
      ghostSpeed: 2,
      bio: 'Salut',
      bioFont: TextFont.molle,
      socialLinks: const {SocialNetwork.github: 'bedbug'},
    );
    final bundle = ExchangeBundle(
      contents: [
        ExchangedContent(content: _text(), signature: signature),
        ExchangedContent(
          content: LinkContent(
            id: 'link',
            createdAt: _date,
            updatedAt: _date,
            signatureId: 'anonymous',
            origin: ContentOrigin.public,
            broadcastScore: 1,
            survivalScore: 1,
            displayScore: 1,
            bounce: 0,
            sizeInBytes: 0,
            flair: 'liens',
            title: 'Un lien',
            url: 'https://example.com',
            ogTitle: 'Exemple',
          ),
        ),
        ExchangedContent(
          content: MediaContent(
            id: 'media',
            createdAt: _date,
            updatedAt: _date,
            signatureId: 'anonymous',
            origin: ContentOrigin.public,
            broadcastScore: 1,
            survivalScore: 1,
            displayScore: 1,
            bounce: 0,
            sizeInBytes: 0,
            flair: 'images',
            title: 'Une image',
            media: const [ContentMedia(url: 'https://i.imgur.com/a.gif', kind: MediaKind.gif)],
          ),
        ),
        ExchangedContent(
          content: DrawingContent(
            id: 'drawing',
            createdAt: _date,
            updatedAt: _date,
            signatureId: 'anonymous',
            origin: ContentOrigin.public,
            broadcastScore: 1,
            survivalScore: 1,
            displayScore: 1,
            bounce: 0,
            sizeInBytes: 0,
            flair: 'art',
            title: 'Un dessin',
            drawing: drawing,
          ),
        ),
      ],
      reactions: [
        Reaction(
          id: 'reaction',
          createdAt: _date,
          updatedAt: _date,
          contentId: 'text',
          authorId: 'local',
          avatarText: '(・ω・)',
          bubbleText: 'trop bien',
          colorArgb: 0xFF00FF00,
          ghostSpeed: 1.5,
          bubbleFont: TextFont.gugi,
        ),
      ],
    );

    final decoded = codec.decodeBundle(codec.encodeBundle(bundle));

    final text = decoded.contents[0].content as TextContent;
    expect(text.id, 'text');
    expect(text.createdAt, _date);
    expect(text.bounce, 3);
    expect(text.flair, 'france');
    expect(text.tags, [Tag.info, Tag.spoiler]);
    expect(text.title, 'Titre');
    expect(text.body, 'Corps du texte');
    // Rien de ce qui est propre à l'appareil émetteur ne voyage.
    expect(text.signatureId, isEmpty);
    expect(text.origin, ContentOrigin.public);
    expect(text.sizeInBytes, 0);

    final decodedSignature = decoded.contents[0].signature!;
    expect(decodedSignature.id, isEmpty);
    expect(decodedSignature.pseudo, 'bedbug');
    expect(decodedSignature.colorArgb, 0xFF112233);
    expect(decodedSignature.ghostSpeed, 2);
    expect(decodedSignature.bio, 'Salut');
    expect(decodedSignature.bioFont, TextFont.molle);
    expect(decodedSignature.socialLinks, {SocialNetwork.github: 'bedbug'});

    final link = decoded.contents[1].content as LinkContent;
    expect(decoded.contents[1].signature, isNull);
    expect(link.url, 'https://example.com');
    expect(link.ogTitle, 'Exemple');
    expect(link.body, isNull);

    final media = decoded.contents[2].content as MediaContent;
    expect(media.media, const [ContentMedia(url: 'https://i.imgur.com/a.gif', kind: MediaKind.gif)]);

    final decodedDrawing = decoded.contents[3].content as DrawingContent;
    expect(decodedDrawing.drawing, drawing);

    final reaction = decoded.reactions.single;
    expect(reaction.id, 'reaction');
    expect(reaction.authorId, isEmpty);
    expect(reaction.bubbleText, 'trop bien');
    expect(reaction.ghostSpeed, 1.5);
    expect(reaction.bubbleFont, TextFont.gugi);
  });

  test('le texte répétitif se compresse', () {
    final bundle = ExchangeBundle(
      contents: [for (var index = 0; index < 20; index++) ExchangedContent(content: _text())],
      reactions: const [],
    );
    final encoded = codec.encodeBundle(bundle);
    final uncompressed = ZLibDecoder().convert(encoded);
    expect(encoded.length, lessThan(uncompressed.length / 3));
  });

  test('refuse un message illisible, d\'une autre version ou mal typé', () {
    expect(() => codec.decodeOffer(Uint8List.fromList([1, 2, 3, 4])), throwsA(isA<DataException>()));
    expect(
      () => codec.decodeOffer(_rawMessage({'version': exchangeFormatVersion + 1, 'contents': <Object>[]})),
      throwsA(isA<DataException>()),
    );
    expect(
      () => codec.decodeRequest(
        _rawMessage({'version': exchangeFormatVersion, 'contentIds': 'a', 'reactionContentIds': <Object>[]}),
      ),
      throwsA(isA<DataException>()),
    );
    expect(
      () => codec.decodeBundle(
        _rawMessage({
          'version': exchangeFormatVersion,
          'contents': [
            {'id': 'a', 'type': 99},
          ],
          'reactions': <Object>[],
        }),
      ),
      throwsA(isA<DataException>()),
    );
  });

  test('interrompt un message qui se décompresse au-delà de la limite', () {
    final bomb = Uint8List.fromList(ZLibEncoder().convert(Uint8List(maxDecompressedExchangeBytes + 1)));
    expect(bomb.length, lessThan(50 * 1024));
    expect(() => codec.decodeOffer(bomb), throwsA(isA<DataException>()));
  });
}
