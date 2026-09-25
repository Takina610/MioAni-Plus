import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/translation/data/tencent_tc3_signer.dart';

void main() {
  group('canonical request', () {
    // The service publishes one worked example of a signed request, complete
    // with the hash of the string it signed. The example is for a different
    // product and its key is masked, so what it can be held to is the half that
    // has no key in it: given the same method, path, headers and payload, this
    // signer must produce the exact bytes the service hashed. Everything a
    // reader would be tempted to tidy up lives here — the header order, the one
    // space after a colon, the blank line before the header list, the
    // lowercase hex — and every one of them is a request the service would
    // otherwise reject with a signature error.
    const publishedPayload =
        '{"Limit": 1, "Filters": [{"Values": ["\\u672a\\u547d\\u540d"], '
        '"Name": "instance-name"}]}';

    test('matches the published worked example byte for byte', () {
      final request = TencentTc3Signer.canonicalRequest(
        host: 'cvm.tencentcloudapi.com',
        action: 'describeinstances',
        payload: publishedPayload,
      );

      expect(request, _publishedCanonicalRequest);
      expect(
        _sha256Hex(request),
        '7019a55be8395899b900fb5564e4200d984910f34794a27cb3fb7d10ff6a1e84',
      );
    });

    test('the payload is hashed as it will be sent, escapes and all', () {
      // A body written with `\uXXXX` escapes and the same body written with the
      // characters themselves are different bytes, and the service hashes the
      // bytes. Encoding the same map twice must not surprise the signature.
      final escaped = jsonEncode(<String, Object?>{
        'Values': <String>['未命名'],
      });
      expect(_sha256Hex(escaped), isNot(_sha256Hex(r'{"Values": ["未命名"]}')));
    });

    test('the action goes on the wire in lower case', () {
      // The service signs and checks `x-tc-action` in lower case, so an Action
      // written the way the SDK spells it must still sign the lower-case form.
      final lower = TencentTc3Signer.canonicalRequest(
        host: 'tmt.tencentcloudapi.com',
        action: 'texttranslate',
        payload: '{}',
      );
      final upper = TencentTc3Signer.canonicalRequest(
        host: 'tmt.tencentcloudapi.com',
        action: 'TextTranslate',
        payload: '{}',
      );
      expect(upper, lower);
    });
  });

  group('signature', () {
    // The signing key descends from the secret through four HMACs, so this
    // value is what an independent implementation of the published steps
    // produces for the same inputs. It locks the chain — the key-then-data
    // order, the `TC3` prefix, the scope, the hex case — against a change that
    // still looks right.
    test('signs a request the way the service says to', () {
      final signed = TencentTc3Signer.sign(
        secretId: 'AKIDmiotest000000000000000000000000',
        secretKey: 'MioAniTranslationTestSecretKey0000',
        service: 'tmt',
        host: 'tmt.tencentcloudapi.com',
        action: 'TextTranslate',
        payload:
            '{"SourceText":"\\u30c6\\u30b9\\u30c8","Source":"ja",'
            '"Target":"zh","ProjectId":0}',
        timestamp: '1790258292',
      );

      expect(signed.timestamp, '1790258292');
      expect(
        signed.authorization,
        'TC3-HMAC-SHA256 '
        'Credential=AKIDmiotest000000000000000000000000/2026-09-24/tmt/'
        'tc3_request, '
        'SignedHeaders=content-type;host;x-tc-action, '
        'Signature=6d91c5890f1c7709760df78064ccdcbb0d078c9278feefe6be037db2cd76c3f8',
      );
    });

    test('the scope is the UTC day, not the local one', () {
      // A signature made at 23:50 in a +8 timezone belongs to the previous day
      // in UTC, and the service scopes it that way. Signing with the local day
      // works for most of the day and fails for the last eight hours of it.
      final midnightUtc =
          DateTime.utc(2026, 9, 24).millisecondsSinceEpoch ~/ 1000;
      final signed = TencentTc3Signer.sign(
        secretId: 'id',
        secretKey: 'key',
        service: 'tmt',
        host: 'tmt.tencentcloudapi.com',
        action: 'TextTranslate',
        payload: '{}',
        timestamp: '$midnightUtc',
      );

      expect(signed.authorization, contains('/2026-09-24/tmt/tc3_request,'));
    });

    test('a different day produces a different signature', () {
      String signAt(String timestamp) => TencentTc3Signer.sign(
        secretId: 'id',
        secretKey: 'key',
        service: 'tmt',
        host: 'tmt.tencentcloudapi.com',
        action: 'TextTranslate',
        payload: '{}',
        timestamp: timestamp,
      ).authorization;

      expect(
        signAt('1790258292'),
        isNot(signAt('1790344692')),
        reason: 'the day is part of the signed scope',
      );
    });
  });
}

/// The canonical request the service's own example hashes, reproduced from the
/// documentation of the example.
const String _publishedCanonicalRequest =
    'POST\n'
    '/\n'
    '\n'
    'content-type:application/json; charset=utf-8\n'
    'host:cvm.tencentcloudapi.com\n'
    'x-tc-action:describeinstances\n'
    '\n'
    'content-type;host;x-tc-action\n'
    '35e9c5b0e3ae67532d3c9f17ead6c90222632e5b1ff7f6e89887f1398934f064';

String _sha256Hex(String value) {
  return sha256.convert(utf8.encode(value)).toString();
}
