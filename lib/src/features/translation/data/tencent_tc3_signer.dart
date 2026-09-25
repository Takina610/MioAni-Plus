import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A signed request: the headers the translation service checks it against.
final class TencentRequestSignature {
  const TencentRequestSignature({
    required this.authorization,
    required this.timestamp,
  });

  /// The `Authorization` header, which carries the identity, the scope the
  /// request was signed for, and the signature itself.
  final String authorization;

  /// Unix seconds the request was signed at. The service rejects a request
  /// whose timestamp is more than a few minutes from its own clock, so this is
  /// the build of the request rather than the moment it is sent.
  final String timestamp;
}

/// Tencent Cloud's request signing, TC3-HMAC-SHA256.
///
/// The steps are the service's own and are followed literally: a canonical
/// request is assembled from the method, the path, the headers and a hash of
/// the body; the string that gets signed adds the timestamp and the scope; and
/// the signing key is derived from the secret by four rounds of HMAC.
///
/// What makes this worth its own file and its own test is that the service
/// compares the signed bytes to the bytes it receives, so the formatting *is*
/// the protocol: the header order, the exactly-one-space after a header's
/// colon, the blank line before the signed-header list, and the lowercase hex
/// are all things a reader would tidy up and a request would then fail on.
abstract final class TencentTc3Signer {
  /// Signs a JSON request to [host] for [service].
  ///
  /// [signedHeaders] are the headers the signature covers, by their lowercase
  /// names; their values are taken from [headers]. The service requires
  /// `content-type` and `host` to be among them.
  static TencentRequestSignature sign({
    required String secretId,
    required String secretKey,
    required String service,
    required String host,
    required String action,
    required String payload,
    required String timestamp,
    String method = 'POST',
    String path = '/',
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      'host': host,
      'x-tc-action': action.toLowerCase(),
      ...?extraHeaders,
    };
    final signedHeaderNames = headers.keys.toList()..sort();
    final canonicalHeaders = signedHeaderNames
        .map((name) => '$name:${headers[name]!.trim()}\n')
        .join();
    final signedHeaders = signedHeaderNames.join(';');
    final canonicalRequest = <String>[
      method,
      path,
      // A POST carries no query string, and the line stays even when it is
      // empty: the format is positional.
      '',
      canonicalHeaders,
      signedHeaders,
      _sha256Hex(payload),
    ].join('\n');

    final date = DateTime.fromMillisecondsSinceEpoch(
      int.parse(timestamp) * 1000,
      isUtc: true,
    );
    final day = _day(date);
    final credentialScope = '$day/$service/tc3_request';
    final stringToSign = <String>[
      'TC3-HMAC-SHA256',
      timestamp,
      credentialScope,
      _sha256Hex(canonicalRequest),
    ].join('\n');

    // The signing key descends from the secret in three steps, one per part of
    // the scope, so that a key leaked for one day and one service cannot sign
    // for another.
    final secretDate = _hmac(utf8.encode('TC3$secretKey'), day);
    final secretService = _hmac(secretDate, service);
    final secretSigning = _hmac(secretService, 'tc3_request');
    final signature = _hex(_hmac(secretSigning, stringToSign));

    return TencentRequestSignature(
      timestamp: timestamp,
      authorization:
          'TC3-HMAC-SHA256 '
          'Credential=$secretId/$credentialScope, '
          'SignedHeaders=$signedHeaders, '
          'Signature=$signature',
    );
  }

  /// The canonical request, exposed so a test can hold it to the worked example
  /// the service publishes.
  static String canonicalRequest({
    required String host,
    required String action,
    required String payload,
    String method = 'POST',
    String path = '/',
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      'host': host,
      'x-tc-action': action.toLowerCase(),
      ...?extraHeaders,
    };
    final names = headers.keys.toList()..sort();
    return <String>[
      method,
      path,
      '',
      names.map((name) => '$name:${headers[name]!.trim()}\n').join(),
      names.join(';'),
      _sha256Hex(payload),
    ].join('\n');
  }

  /// `YYYY-MM-DD` in UTC, which is the day the signature is scoped to. A
  /// signature made just before midnight local time is scoped to whatever day
  /// it is in UTC, and the service reads it that way too.
  static String _day(DateTime utc) {
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }

  static List<int> _hmac(List<int> key, String data) {
    return Hmac(sha256, key).convert(utf8.encode(data)).bytes;
  }

  static String _sha256Hex(String value) {
    return _hex(sha256.convert(utf8.encode(value)).bytes);
  }

  static String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
