import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

abstract interface class ImagePipeline {
  Future<Uint8List> load(Uri uri);
}

final class DioImagePipeline implements ImagePipeline {
  DioImagePipeline({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;
  final Map<Uri, Uint8List> _memory = <Uri, Uint8List>{};

  @override
  Future<Uint8List> load(Uri uri) {
    final cached = _memory[uri];
    if (cached != null) return Future<Uint8List>.value(cached);
    uriPolicy.validate(NetworkSource.bangumiImages, uri);
    return coordinator.execute<Uint8List>(
      source: NetworkSource.bangumiImages,
      key: 'GET:$uri',
      retryEligible: true,
      operation: () async {
        try {
          final response = await dio.getUri<List<int>>(
            uri,
            options: Options(responseType: ResponseType.bytes),
          );
          final bytes = response.data;
          if (bytes == null || bytes.isEmpty) {
            throw const InvalidPayloadFailure();
          }
          final result = Uint8List.fromList(bytes);
          _memory[uri] = result;
          return result;
        } on DioException catch (error) {
          throw mapDioFailure(error);
        }
      },
    );
  }
}
