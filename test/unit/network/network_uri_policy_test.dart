import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

void main() {
  const policy = NetworkUriPolicy();

  test('allows only registered HTTPS hosts on the default port', () {
    expect(
      () => policy.validate(
        NetworkSource.bangumiApi,
        Uri.parse('https://api.bgm.tv/calendar'),
      ),
      returnsNormally,
    );
    expect(
      () => policy.validate(
        NetworkSource.bangumiImages,
        Uri.parse('https://lain.bgm.tv/pic/cover/l/test.jpg'),
      ),
      returnsNormally,
    );
  });

  for (final uri in <String>[
    'http://api.bgm.tv/calendar',
    'https://api.bgm.tv:8443/calendar',
    'https://example.com/calendar',
  ]) {
    test('rejects unsafe API URI $uri', () {
      expect(
        () => policy.validate(NetworkSource.bangumiApi, Uri.parse(uri)),
        throwsA(isA<BrowserPolicyFailure>()),
      );
    });
  }
}
