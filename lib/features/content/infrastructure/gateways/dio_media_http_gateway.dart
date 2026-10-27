import 'dart:typed_data';

import 'package:bedbug/features/content/domain/gateways/media_http_gateway.dart';
import 'package:bedbug/features/content/domain/object_values/safe_url.dart';
import 'package:bedbug/shared/config/http_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [MediaHttpGateway].
final mediaHttpGatewayProvider = Provider<MediaHttpGateway>((ref) => DioMediaHttpGateway());

/// [MediaHttpGateway] basé sur Dio, qui ne suit jamais de redirection et borne la taille des réponses.
class DioMediaHttpGateway implements MediaHttpGateway {
  /// Crée un [DioMediaHttpGateway].
  DioMediaHttpGateway();

  /// Client HTTP configuré pour ne rien faire de lui-même : ni redirection, ni rejet selon le code de réponse.
  final Dio _dio = Dio(
    BaseOptions(
      followRedirects: false,
      maxRedirects: 0,
      validateStatus: (_) => true,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.stream,
      headers: {'User-Agent': appUserAgent},
    ),
  );

  @override
  Future<MediaHttpResponse> get(SafeUrl url, {required int maxBytes, required bool isBodyNeeded}) async {
    final cancelToken = CancelToken();
    try {
      final response = await _dio.get<ResponseBody>(
        url.url,
        cancelToken: cancelToken,
        // Sans corps à lire, un seul octet suffit à savoir que le média répond.
        options: Options(headers: isBodyNeeded ? null : {'Range': 'bytes=0-0'}),
      );
      final statusCode = response.statusCode ?? 0;

      if (statusCode >= 300 && statusCode < 400) {
        cancelToken.cancel();
        final location = response.headers.value('location');
        if (location == null) {
          return const MediaHttpError(MediaHttpErrorKind.unavailable);
        }
        return MediaHttpRedirect(location);
      }
      if (statusCode == 404 || statusCode == 410) {
        cancelToken.cancel();
        return const MediaHttpError(MediaHttpErrorKind.notFound);
      }
      if (statusCode < 200 || statusCode >= 300) {
        cancelToken.cancel();
        return const MediaHttpError(MediaHttpErrorKind.unavailable);
      }
      if (!isBodyNeeded) {
        cancelToken.cancel();
        return MediaHttpBody(Uint8List(0));
      }

      final declaredLength = int.tryParse(response.headers.value('content-length') ?? '');
      if (declaredLength != null && declaredLength > maxBytes) {
        cancelToken.cancel();
        return const MediaHttpError(MediaHttpErrorKind.tooLarge);
      }
      // La taille annoncée n'engage pas le serveur : elle est revérifiée au fil de la lecture.
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.data!.stream) {
        builder.add(chunk);
        if (builder.length > maxBytes) {
          cancelToken.cancel();
          return const MediaHttpError(MediaHttpErrorKind.tooLarge);
        }
      }
      return MediaHttpBody(builder.takeBytes());
    } on DioException {
      return const MediaHttpError(MediaHttpErrorKind.unavailable);
    }
  }
}
