import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/translation/data/tencent_translation_source.dart';
import 'package:mio_ani/src/features/translation/data/translation_source.dart';
import 'package:mio_ani/src/features/translation/domain/translation_credentials.dart';

void main() {
  test('asks for a Japanese text in Chinese and reads the answer', () async {
    final adapter = _QueueAdapter(<Object?>[
      <String, Object?>{
        'Response': <String, Object?>{
          'TargetText': '地球最喜欢！小鸡',
          'Source': 'ja',
          'Target': 'zh',
          'UsedAmount': 11,
          'RequestId': 'req-1',
        },
      },
    ]);
    final source = _source(adapter);

    final translated = await source.translate(
      '地球大好き！きっくん',
      from: TranslationLanguage.japanese,
    );

    expect(translated, '地球最喜欢！小鸡');
    final request = adapter.requests.single;
    expect(request.uri.host, 'tmt.tencentcloudapi.com');
    expect(request.uri.scheme, 'https');
    expect(request.headers['X-TC-Action'], 'TextTranslate');
    expect(request.headers['X-TC-Version'], '2018-03-21');
    expect(request.headers['X-TC-Region'], 'ap-guangzhou');
    // The signature covers these headers, so the request carries them or the
    // service cannot check it.
    expect(request.headers['Authorization'], startsWith('TC3-HMAC-SHA256 '));
    final body = jsonDecode(adapter.bodies.single) as Map<String, Object?>;
    expect(body['SourceText'], '地球大好き！きっくん');
    expect(body['Source'], 'ja');
    expect(body['Target'], 'zh');
  });

  test('an English title is asked for as English', () async {
    final adapter = _QueueAdapter(<Object?>[
      <String, Object?>{
        'Response': <String, Object?>{'TargetText': '断熊'},
      },
    ]);

    await _source(
      adapter,
    ).translate('Breaking Bear', from: TranslationLanguage.english);

    final body = jsonDecode(adapter.bodies.single) as Map<String, Object?>;
    expect(body['Source'], 'en');
  });

  test('a refusal in the body is a failure, not a translation', () async {
    // The service answers 200 to its own refusals, so a caller that only looked
    // at the status code would show an error message where a translation goes.
    final adapter = _QueueAdapter(<Object?>[
      <String, Object?>{
        'Response': <String, Object?>{
          'Error': <String, Object?>{
            'Code': 'AuthFailure.SignatureFailure',
            'Message': 'The signature is invalid.',
          },
          'RequestId': 'req-2',
        },
      },
    ]);

    await expectLater(
      _source(adapter).translate('テスト', from: TranslationLanguage.japanese),
      throwsA(
        isA<TranslationFailure>()
            .having(
              (error) => error.failure.kind,
              'kind',
              AppFailureKind.forbidden,
            )
            .having((error) => error.message, 'message', contains('SecretId')),
      ),
    );
  });

  test('a used-up free tier says so instead of blaming the network', () async {
    final adapter = _QueueAdapter(<Object?>[
      <String, Object?>{
        'Response': <String, Object?>{
          'Error': <String, Object?>{
            'Code': 'FailedOperation.NoFreeAmount',
            'Message': 'no free amount',
          },
        },
      },
    ]);

    await expectLater(
      _source(adapter).translate('テスト', from: TranslationLanguage.japanese),
      throwsA(
        isA<TranslationFailure>().having(
          (error) => error.message,
          'message',
          contains('免费额度'),
        ),
      ),
    );
  });

  test('a payload with no translation in it is rejected', () async {
    final adapter = _QueueAdapter(<Object?>[
      <String, Object?>{
        'Response': <String, Object?>{'TargetText': '  '},
      },
    ]);

    await expectLater(
      _source(adapter).translate('テスト', from: TranslationLanguage.japanese),
      throwsA(isA<TranslationFailure>()),
    );
  });

  test(
    'a long synopsis is split into requests the service will take',
    () async {
      // The service takes 6000 characters in one call. A synopsis longer than
      // that is rare and entirely possible, and dropping it would leave the one
      // page that most needs translating without one.
      final long = List<String>.generate(
        400,
        (index) => '第$index行'.padRight(40, 'あ'),
      ).join('\n');
      expect(long.length, greaterThan(6000));
      final adapter = _QueueAdapter(<Object?>[
        for (var index = 0; index < 10; index += 1)
          <String, Object?>{
            'Response': <String, Object?>{'TargetText': '第$index段译文'},
          },
      ]);

      final translated = await _source(
        adapter,
      ).translate(long, from: TranslationLanguage.japanese);

      expect(adapter.bodies.length, greaterThan(1));
      for (final body in adapter.bodies) {
        final text = (jsonDecode(body) as Map<String, Object?>)['SourceText']!;
        expect((text as String).length, lessThan(6000));
      }
      // The pieces come back joined in the order they were sent, so the reader
      // gets one translation rather than a list of them.
      expect(translated.split('\n'), contains('第0段译文'));
    },
  );

  test('an empty text never becomes a request', () async {
    final adapter = _QueueAdapter(<Object?>[]);

    expect(
      await _source(
        adapter,
      ).translate('   ', from: TranslationLanguage.japanese),
      '',
    );
    expect(adapter.requests, isEmpty);
  });
}

TencentTranslationSource _source(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  )..httpClientAdapter = adapter;
  return TencentTranslationSource(
    dio: dio,
    coordinator: RequestCoordinator(),
    credentials: const TranslationCredentials(
      secretId: 'AKIDmiotest000000000000000000000000',
      secretKey: 'MioAniTranslationTestSecretKey0000',
    ),
    clock: () => DateTime.utc(2026, 9, 24, 12),
  );
}

final class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this.responses);

  final List<Object?> responses;
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<String> bodies = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    bodies.add(options.data is String ? options.data! as String : '');
    if (responses.isEmpty) {
      return ResponseBody.fromString(jsonEncode(<String, Object?>{}), 200);
    }
    return ResponseBody.fromString(
      jsonEncode(responses.removeAt(0)),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
