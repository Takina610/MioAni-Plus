import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mio_ani/src/features/anime_detail/data/bangumi_anime_sections_source.dart';
import 'package:mio_ani/src/features/anime_detail/domain/anime_detail_sections.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

final animeDetailSectionsSourceProvider = Provider<AnimeDetailSectionsSource>((
  ref,
) {
  return BangumiAnimeSectionsSource(
    dio: ref.watch(dioProvider),
    coordinator: ref.watch(requestCoordinatorProvider),
  );
});

final animeRelationsRefreshProvider = StateProvider.autoDispose
    .family<int, AnimeSourceId>((ref, id) => 0);
final animeCharactersRefreshProvider = StateProvider.autoDispose
    .family<int, AnimeSourceId>((ref, id) => 0);
final animeStaffRefreshProvider = StateProvider.autoDispose
    .family<int, AnimeSourceId>((ref, id) => 0);

final animeRelationsProvider = FutureProvider.autoDispose
    .family<List<AnimeRelation>, AnimeSourceId>((ref, id) {
      final refresh = ref.watch(animeRelationsRefreshProvider(id));
      return ref
          .watch(animeDetailSectionsSourceProvider)
          .fetchRelations(id, forceNewGeneration: refresh > 0);
    });

final animeCharactersProvider = FutureProvider.autoDispose
    .family<List<AnimeCharacterCredit>, AnimeSourceId>((ref, id) {
      final refresh = ref.watch(animeCharactersRefreshProvider(id));
      return ref
          .watch(animeDetailSectionsSourceProvider)
          .fetchCharacters(id, forceNewGeneration: refresh > 0);
    });

final animeStaffProvider = FutureProvider.autoDispose
    .family<List<AnimeStaffCredit>, AnimeSourceId>((ref, id) {
      final refresh = ref.watch(animeStaffRefreshProvider(id));
      return ref
          .watch(animeDetailSectionsSourceProvider)
          .fetchStaff(id, forceNewGeneration: refresh > 0);
    });

void refreshAnimeRelations(WidgetRef ref, AnimeSourceId id) {
  ref.read(animeRelationsRefreshProvider(id).notifier).state++;
}

void refreshAnimeCharacters(WidgetRef ref, AnimeSourceId id) {
  ref.read(animeCharactersRefreshProvider(id).notifier).state++;
}

void refreshAnimeStaff(WidgetRef ref, AnimeSourceId id) {
  ref.read(animeStaffRefreshProvider(id).notifier).state++;
}
