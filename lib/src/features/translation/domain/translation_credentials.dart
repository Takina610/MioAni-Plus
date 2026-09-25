/// What a page needs in order to ask for a translation: who is asking, and
/// which of the service's regions the request is signed for.
/// Both halves of the key are secrets, and they are configured once at build
/// time rather than typed into the app: see [TranslationCredentials.fromEnvironment].
final class TranslationCredentials {
  const TranslationCredentials({
    required this.secretId,
    required this.secretKey,
    this.region = defaultRegion,
  });

  /// The region the request is signed for. The translation service is offered
  /// in one place, and the region is part of the signature rather than a choice
  /// of endpoint, so it is a constant with an override for another one.
  static const String defaultRegion = 'ap-guangzhou';

  final String secretId;
  final String secretKey;
  final String region;

  /// Whether a request can be signed at all. A build with no key in it has no
  /// translations, and says so by not offering them.
  bool get isConfigured =>
      secretId.trim().isNotEmpty && secretKey.trim().isNotEmpty;

  /// The credentials this build was given.
  ///
  /// They come from the build command rather than from the app — nothing here
  /// reads a file or a settings row, because a key that a reader can type into
  /// a screen is a key that ends up in a screenshot:
  ///
  /// ```
  /// flutter build apk --debug \
  ///   --dart-define=MIO_ANI_TRANSLATE_SECRET_ID=<SecretId> \
  ///   --dart-define=MIO_ANI_TRANSLATE_SECRET_KEY=<SecretKey>
  /// ```
  factory TranslationCredentials.fromEnvironment() {
    return const TranslationCredentials(
      secretId: String.fromEnvironment(_secretIdKey),
      secretKey: String.fromEnvironment(_secretKeyKey),
      region: String.fromEnvironment(_regionKey, defaultValue: defaultRegion),
    );
  }

  static const String _secretIdKey = 'MIO_ANI_TRANSLATE_SECRET_ID';
  static const String _secretKeyKey = 'MIO_ANI_TRANSLATE_SECRET_KEY';
  static const String _regionKey = 'MIO_ANI_TRANSLATE_REGION';

  @override
  String toString() => 'TranslationCredentials(region: $region)';
}
