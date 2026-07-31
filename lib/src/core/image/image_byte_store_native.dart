import 'dart:io';
import 'dart:typed_data';

import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/image/image_storage_key.dart';
import 'package:path_provider/path_provider.dart';

typedef ImageCacheDirectoryLoader = Future<Directory> Function();

final class NativeFileImageByteStore implements ImageByteStore {
  NativeFileImageByteStore({ImageCacheDirectoryLoader? cacheDirectoryLoader})
    : _cacheDirectoryLoader = cacheDirectoryLoader ?? getTemporaryDirectory;

  static const String _applicationDirectoryName = 'mio_ani';
  static const String _namespaceDirectoryName = 'image_cache_v1';
  static int _temporaryFileSequence = 0;

  final ImageCacheDirectoryLoader _cacheDirectoryLoader;

  @override
  Future<Uint8List?> read(Uri uri) async {
    try {
      final target = await _targetFile(uri, createNamespace: false);
      if (!await target.exists()) return null;
      return Uint8List.fromList(await target.readAsBytes());
    } on Exception {
      return null;
    }
  }

  @override
  Future<ImageByteWriteResult?> write(Uri uri, Uint8List bytes) async {
    File? temporary;
    try {
      final target = await _targetFile(uri, createNamespace: true);
      temporary = File(
        '${target.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.'
        '${_temporaryFileSequence++}.tmp',
      );
      await temporary.writeAsBytes(bytes, flush: true);
      try {
        await temporary.rename(target.path);
      } on FileSystemException {
        if (await target.exists()) await target.delete();
        await temporary.rename(target.path);
      }
      return ImageByteWriteResult(
        storageKey: createImageStorageKey(uri),
        backend: ImageCacheBackend.nativeFile,
      );
    } on Exception {
      // A rebuildable image cache must never make the network image path fail.
      return null;
    } finally {
      try {
        if (temporary != null && await temporary.exists()) {
          await temporary.delete();
        }
      } on Exception {
        // A leftover temporary cache file must not fail image loading.
      }
    }
  }

  @override
  Future<void> delete(Uri uri) async {
    try {
      final target = await _targetFile(uri, createNamespace: false);
      if (await target.exists()) await target.delete();
    } on Exception {
      // Missing or unavailable cache storage is equivalent to a cache miss.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final namespace = await _namespaceDirectory(create: false);
      final type = await FileSystemEntity.type(
        namespace.path,
        followLinks: false,
      );
      switch (type) {
        case FileSystemEntityType.directory:
          await namespace.delete(recursive: true);
        case FileSystemEntityType.link:
          await Link(namespace.path).delete();
        case FileSystemEntityType.file:
          await File(namespace.path).delete();
        case FileSystemEntityType.notFound:
        case FileSystemEntityType.pipe:
        case FileSystemEntityType.unixDomainSock:
          return;
      }
    } on Exception {
      // Clearing a rebuildable cache is best-effort.
    }
  }

  Future<File> _targetFile(Uri uri, {required bool createNamespace}) async {
    final namespace = await _namespaceDirectory(create: createNamespace);
    return File(
      '${namespace.path}${Platform.pathSeparator}'
      '${createImageStorageKey(uri)}.bin',
    );
  }

  Future<Directory> _namespaceDirectory({required bool create}) async {
    final suppliedRoot = await _cacheDirectoryLoader();
    if (create) await suppliedRoot.create(recursive: true);

    final root = await suppliedRoot.exists()
        ? Directory(await suppliedRoot.resolveSymbolicLinks())
        : suppliedRoot.absolute;
    final rootPath = _trimTrailingSeparators(root.absolute.path);
    final namespacePath =
        '$rootPath${Platform.pathSeparator}'
        '$_applicationDirectoryName${Platform.pathSeparator}'
        '$_namespaceDirectoryName';
    final namespace = Directory(namespacePath).absolute;
    final expectedPrefix = '$rootPath${Platform.pathSeparator}';
    if (!_comparablePath(
      namespace.path,
    ).startsWith(_comparablePath(expectedPrefix))) {
      throw StateError('Image cache namespace escaped its cache root.');
    }
    if (create) await namespace.create(recursive: true);
    return namespace;
  }

  static String _trimTrailingSeparators(String path) {
    var result = path;
    while (result.length > 3 &&
        (result.endsWith('/') || result.endsWith(r'\'))) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String _comparablePath(String path) {
    final normalized = path.replaceAll(r'\', '/');
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }
}
