import 'dart:io';
import 'dart:typed_data';

import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/image/image_storage_key.dart';
import 'package:path_provider/path_provider.dart';

typedef ImageCacheDirectoryLoader = Future<Directory> Function();

/// The covers this device has already downloaded, one file each.
///
/// The store's own job is small — turn a URL into a path, read or write the
/// bytes — but the path is not free to work out. It starts at the platform's
/// cache directory, which is a channel call to Android, and the check that
/// keeps the namespace inside it resolves symbolic links, which walks the path.
/// Both answers are the same for the whole life of the process, so they are
/// worked out once and kept (see [_namespaceDirectory]): a poster grid asks for
/// a dozen covers at the same moment, and paying for the same platform call
/// twelve times is what made a cached grid as slow as an uncached one.
final class NativeFileImageByteStore implements ImageByteStore {
  NativeFileImageByteStore({ImageCacheDirectoryLoader? cacheDirectoryLoader})
    : _cacheDirectoryLoader = cacheDirectoryLoader ?? getTemporaryDirectory;

  static const String _applicationDirectoryName = 'mio_ani';
  static const String _namespaceDirectoryName = 'image_cache_v1';
  static int _temporaryFileSequence = 0;

  final ImageCacheDirectoryLoader _cacheDirectoryLoader;

  /// The namespace directory, resolved once. A future rather than a directory
  /// so that a dozen callers arriving together wait on one resolution instead
  /// of starting a dozen of them.
  Future<Directory>? _namespace;

  @override
  Future<Uint8List?> read(Uri uri) async {
    try {
      final target = File(_pathIn(await _namespaceDirectory(), uri));
      // No `exists()` first: reading a file that is not there throws, and the
      // catch below is what a miss looks like either way. One syscall saved per
      // cover is one syscall not queued behind the others on a cold grid.
      return Uint8List.fromList(await target.readAsBytes());
    } on Exception {
      return null;
    }
  }

  @override
  Future<ImageByteWriteResult?> write(Uri uri, Uint8List bytes) async {
    File? temporary;
    try {
      final target = File(_pathIn(await _namespaceDirectory(), uri));
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
      final target = File(_pathIn(await _namespaceDirectory(), uri));
      if (await target.exists()) await target.delete();
    } on Exception {
      // Missing or unavailable cache storage is equivalent to a cache miss.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final namespace = await _namespaceDirectory();
      // The directory the memo holds is about to be gone: drop it so the next
      // caller resolves again and gets one made for it, because this store is
      // still where covers go.
      _namespace = null;
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

  static String _pathIn(Directory namespace, Uri uri) {
    return '${namespace.path}${Platform.pathSeparator}'
        '${createImageStorageKey(uri)}.bin';
  }

  /// The directory covers live in, made if it is not there yet.
  ///
  /// The check that the namespace cannot escape the cache root happens once,
  /// here, rather than on every file: it is a property of the cache root and the
  /// name under it, and neither changes while the app runs.
  Future<Directory> _namespaceDirectory() {
    final held = _namespace;
    if (held != null) return held;
    final resolved = _resolveNamespace();
    _namespace = resolved;
    return resolved;
  }

  Future<Directory> _resolveNamespace() async {
    final suppliedRoot = await _cacheDirectoryLoader();
    await suppliedRoot.create(recursive: true);
    // Canonical, so the check below compares real paths rather than one that
    // goes through a link: on Android the cache directory is reached through
    // one. A root that will not resolve is used as it stands — the check still
    // holds, it simply compares the path the platform handed over.
    String rootPath;
    try {
      rootPath = _trimTrailingSeparators(
        await suppliedRoot.resolveSymbolicLinks(),
      );
    } on Exception {
      rootPath = _trimTrailingSeparators(suppliedRoot.absolute.path);
    }
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
    await namespace.create(recursive: true);
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
