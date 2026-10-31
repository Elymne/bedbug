import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_decoder_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_frame.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';

/// Taille de l'en-tête d'une trame, en octets : le type (1) puis la longueur de la charge utile (4, gros-boutiste).
const int exchangeFrameHeaderBytes = 5;

/// Implémentation de [ExchangeFrameDecoderGateway] pour le format `[type][longueur][charge utile]`.
///
/// Le décodeur garde un état entre deux appels : l'en-tête en cours, puis la charge utile en cours. La mémoire de la
/// charge utile n'est réservée qu'une fois sa taille vérifiée.
class BinaryExchangeFrameDecoderGateway implements ExchangeFrameDecoderGateway {
  /// Crée un [BinaryExchangeFrameDecoderGateway].
  BinaryExchangeFrameDecoderGateway();

  /// En-tête en cours de lecture.
  final Uint8List _header = Uint8List(exchangeFrameHeaderBytes);

  /// Nombre d'octets déjà lus dans [_header].
  int _headerLength = 0;

  /// Type de la trame dont la charge utile est en cours de lecture.
  ExchangeFrameType? _type;

  /// Charge utile en cours de lecture, `null` tant que l'en-tête n'est pas complet.
  Uint8List? _payload;

  /// Nombre d'octets déjà lus dans [_payload].
  int _payloadLength = 0;

  @override
  List<ExchangeFrame> add(Uint8List bytes) {
    final frames = <ExchangeFrame>[];
    var offset = 0;
    while (offset < bytes.length) {
      final payload = _payload;
      if (payload == null) {
        final count = min(exchangeFrameHeaderBytes - _headerLength, bytes.length - offset);
        _header.setRange(_headerLength, _headerLength + count, bytes, offset);
        _headerLength += count;
        offset += count;
        if (_headerLength == exchangeFrameHeaderBytes) {
          _readHeader(frames);
        }
        continue;
      }

      final count = min(payload.length - _payloadLength, bytes.length - offset);
      payload.setRange(_payloadLength, _payloadLength + count, bytes, offset);
      _payloadLength += count;
      offset += count;
      if (_payloadLength == payload.length) {
        _completeFrame(frames, payload);
      }
    }
    return frames;
  }

  /// Vérifie l'en-tête complet et prépare la lecture de la charge utile.
  ///
  /// Une trame sans charge utile est complète dès son en-tête : aucun octet ne suivra pour la terminer.
  ///
  /// - [frames] : trames complétées, où ajouter celle-ci si elle est vide.
  void _readHeader(List<ExchangeFrame> frames) {
    final header = ByteData.sublistView(_header);
    final type = ExchangeFrameType.fromValue(header.getUint8(0));
    final length = header.getUint32(1);
    if (type == null) {
      throw DataException('BinaryExchangeFrameDecoderGateway', 'type de trame inconnu : ${header.getUint8(0)}');
    }
    if (length > type.maxPayloadBytes) {
      throw DataException('BinaryExchangeFrameDecoderGateway', 'trame ${type.name} trop grande : $length octets');
    }

    _type = type;
    if (length == 0) {
      _completeFrame(frames, Uint8List(0));
      return;
    }
    _payload = Uint8List(length);
  }

  /// Ajoute la trame courante à [frames] et se remet en attente d'un en-tête.
  ///
  /// - [frames] : trames complétées.
  /// - [payload] : charge utile complète de la trame.
  void _completeFrame(List<ExchangeFrame> frames, Uint8List payload) {
    frames.add(ExchangeFrame(_type!, payload));
    _headerLength = 0;
    _payload = null;
    _payloadLength = 0;
    _type = null;
  }
}
