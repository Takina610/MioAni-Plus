import 'package:mio_ani/src/features/imports/domain/import_models.dart';

abstract interface class PublicCollectionSource {
  ImportSource get source;

  Future<PublicAccountProfile> resolveAccount(
    String input, {
    bool forceNewGeneration = false,
  });

  Future<CollectionPage> fetchCollectionPage(
    PublicAccountProfile profile,
    int page, {
    bool forceNewGeneration = false,
  });
}
