import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

final class NetworkUriPolicy {
  const NetworkUriPolicy();

  static const String bangumiApiHost = 'api.bgm.tv';
  static const String bangumiImageHost = 'lain.bgm.tv';
  static const String bangumiSiteHost = 'bgm.tv';
  static const int defaultHttpsPort = 443;

  static final Uri bangumiBaseUri = Uri(scheme: 'https', host: bangumiApiHost);

  static const Map<NetworkSource, Set<String>> _allowedHosts =
      <NetworkSource, Set<String>>{
        NetworkSource.bangumiApi: <String>{bangumiApiHost},
        NetworkSource.bangumiImages: <String>{
          bangumiImageHost,
          bangumiApiHost,
          bangumiSiteHost,
        },
      };

  void validate(NetworkSource source, Uri uri) {
    final defaultPort = !uri.hasPort || uri.port == defaultHttpsPort;
    final hosts = _allowedHosts[source] ?? const <String>{};
    if (uri.scheme != 'https' || !defaultPort || !hosts.contains(uri.host)) {
      throw const BrowserPolicyFailure();
    }
  }
}
