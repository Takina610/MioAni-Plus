import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

final class NetworkUriPolicy {
  const NetworkUriPolicy();

  static const String bangumiApiHost = 'api.bgm.tv';
  static const String bangumiImageHost = 'lain.bgm.tv';
  static const String bangumiSiteHost = 'bgm.tv';
  static const String anilistApiHost = 'graphql.anilist.co';
  static const String anilistImageHost = 's4.anilist.co';

  /// Tencent Cloud's translation service, which is where a page's text goes
  /// when it is asked to be translated. It is not a content source: a
  /// translation is about the words on the page rather than about the work.
  static const String translationHost = 'tmt.tencentcloudapi.com';
  static const int defaultHttpsPort = 443;

  static final Uri bangumiBaseUri = Uri(scheme: 'https', host: bangumiApiHost);
  static final Uri anilistBaseUri = Uri(scheme: 'https', host: anilistApiHost);
  static final Uri translationBaseUri = Uri(
    scheme: 'https',
    host: translationHost,
  );

  static const Map<NetworkSource, Set<String>> _allowedHosts =
      <NetworkSource, Set<String>>{
        NetworkSource.bangumiApi: <String>{bangumiApiHost},
        NetworkSource.bangumiImages: <String>{
          bangumiImageHost,
          bangumiApiHost,
          bangumiSiteHost,
        },
        NetworkSource.anilistApi: <String>{anilistApiHost},
        NetworkSource.anilistImages: <String>{anilistImageHost},
        NetworkSource.translation: <String>{translationHost},
      };

  void validate(NetworkSource source, Uri uri) {
    final defaultPort = !uri.hasPort || uri.port == defaultHttpsPort;
    final hosts = _allowedHosts[source] ?? const <String>{};
    if (uri.scheme != 'https' || !defaultPort || !hosts.contains(uri.host)) {
      throw const BrowserPolicyFailure();
    }
  }

  /// Picks the image source for [uri] by its host, throwing
  /// [BrowserPolicyFailure] for hosts outside the allowed image hosts.
  NetworkSource resolveImageSource(Uri uri) {
    for (final source in <NetworkSource>[
      NetworkSource.bangumiImages,
      NetworkSource.anilistImages,
    ]) {
      try {
        validate(source, uri);
        return source;
      } on BrowserPolicyFailure {
        continue;
      }
    }
    throw const BrowserPolicyFailure();
  }
}
