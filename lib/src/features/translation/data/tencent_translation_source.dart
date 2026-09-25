import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/translation/data/tencent_tc3_signer.dart';
import 'package:mio_ani/src/features/translation/data/translation_source.dart';
import 'package:mio_ani/src/features/translation/domain/translation_credentials.dart';

/// Tencent Cloud's machine translation.
///
/// The service is a single POST that carries the text and a signed request in
/// its headers; everything about *how* the request is signed lives in
/// [TencentTc3Signer], and this is the part that knows what to ask it for.
final class TencentTranslationSource implements TranslationSource {
  const TencentTranslationSource({
    required this.dio,
    required this.credentials,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
    this.clock = DateTime.now,
  });

  final Dio dio;
  final TranslationCredentials credentials;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;

  /// The clock the request is signed against. The service rejects a timestamp
  /// that is minutes away from its own, so this is only ever substituted to
  /// make a test's signature reproducible.
  final DateTime Function() clock;

  static const String _host = NetworkUriPolicy.translationHost;
  static const String _action = 'TextTranslate';
  static const String _version = '2018-03-21';
  static const String _service = 'tmt';

  /// Longest text the service takes in one call. A synopsis is nearly always
  /// shorter; one that is not is sent in pieces rather than dropped.
  static const int _maximumTextLength = 6000;

  /// Where a text is split when it is too long for one call: a piece ends at a
  /// line break when there is one, so a paragraph is not cut mid-sentence.
  static const int _chunkLength = 5000;

  @override
  Future<String> translate(
    String text, {
    required TranslationLanguage from,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final chunks = _chunks(trimmed);
    final translated = <String>[];
    for (final chunk in chunks) {
      translated.add(await _translateChunk(chunk, from: from));
    }
    return translated.join('\n');
  }

  Future<String> _translateChunk(
    String text, {
    required TranslationLanguage from,
  }) {
    return coordinator.execute<String>(
      // One key per text: two rows asking for the same translation share the
      // one request, and nothing else about the page is held up behind it.
      key: 'translate:${from.code}:${text.hashCode}',
      source: NetworkSource.translation,
      retryEligible: true,
      operation: () => _send(text, from: from),
    );
  }

  Future<String> _send(String text, {required TranslationLanguage from}) async {
    final uri = NetworkUriPolicy.translationBaseUri;
    uriPolicy.validate(NetworkSource.translation, uri);
    final timestamp = clock().toUtc().millisecondsSinceEpoch ~/ 1000;
    final payload = jsonEncode(<String, Object?>{
      'SourceText': text,
      'Source': from.code,
      'Target': 'zh',
      'ProjectId': 0,
    });
    final signature = TencentTc3Signer.sign(
      secretId: credentials.secretId,
      secretKey: credentials.secretKey,
      service: _service,
      host: _host,
      action: _action,
      payload: payload,
      timestamp: '$timestamp',
    );

    final Response<Object?> response;
    try {
      response = await dio.postUri<Object?>(
        uri,
        data: payload,
        options: Options(
          contentType: 'application/json; charset=utf-8',
          headers: <String, String>{
            'X-TC-Action': _action,
            'X-TC-Version': _version,
            'X-TC-Region': credentials.region,
            'X-TC-Timestamp': signature.timestamp,
            'Authorization': signature.authorization,
          },
        ),
      );
    } on DioException catch (error) {
      throw TranslationFailure(
        error.error is AppFailure
            ? error.error! as AppFailure
            : mapDioFailure(error),
      );
    }
    return _readBody(response.data);
  }

  /// The service answers `200` to everything, including its own refusals, so
  /// the body is what says whether the translation happened.
  static String _readBody(Object? body) {
    if (body is! Map<Object?, Object?>) {
      throw const TranslationFailure(InvalidPayloadFailure());
    }
    final response = body['Response'];
    if (response is! Map<Object?, Object?>) {
      throw const TranslationFailure(InvalidPayloadFailure());
    }
    if (response['Error'] case final Map<Object?, Object?> error) {
      throw _failure(error);
    }
    final text = response['TargetText'];
    if (text is! String || text.trim().isEmpty) {
      throw const TranslationFailure(
        InvalidPayloadFailure(),
        detail: '翻译服务没有返回译文',
      );
    }
    return text.trim();
  }

  static TranslationFailure _failure(Map<Object?, Object?> error) {
    final code = error['Code'];
    final name = code is String ? code : '';
    // A wrong or expired key is the one failure a reader cannot do anything
    // about, so it says what to look at instead of blaming the network.
    if (name.startsWith('AuthFailure')) {
      return const TranslationFailure.rejectedKey();
    }
    if (name == 'RequestLimitExceeded') {
      return const TranslationFailure(
        RateLimitedFailure(),
        detail: '翻译请求过于频繁，请稍后再试',
      );
    }
    if (name == 'FailedOperation.NoFreeAmount' ||
        name == 'FailedOperation.ServiceIsolate' ||
        name == 'FailedOperation.UserNotRegistered') {
      return const TranslationFailure(
        ForbiddenFailure(),
        detail: '翻译服务的免费额度已用尽或未开通',
      );
    }
    return const TranslationFailure(UpstreamFailure());
  }

  /// [text] split into pieces the service will take, preferring to break at a
  /// line rather than inside one.
  static List<String> _chunks(String text) {
    if (text.length <= _maximumTextLength) return <String>[text];
    final chunks = <String>[];
    var rest = text;
    while (rest.length > _maximumTextLength) {
      final window = rest.substring(0, _chunkLength);
      final breakAt = window.lastIndexOf('\n');
      final cut = breakAt > 0 ? breakAt : window.length;
      chunks.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trim();
    }
    if (rest.isNotEmpty) chunks.add(rest);
    return chunks;
  }
}
