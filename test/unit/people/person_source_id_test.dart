import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

void main() {
  test('parses and round-trips all supported source IDs', () {
    final ids = <PersonSourceId>[
      PersonSourceId.fromBangumiCharacter(1),
      PersonSourceId.fromBangumiPerson(2),
      PersonSourceId.fromAniListCharacter(3),
      PersonSourceId.fromAniListStaff(4),
    ];
    for (final id in ids) {
      expect(PersonSourceId.tryParse(id.value), id);
    }
    expect(
      PersonSourceId.tryParse('bgm-character-5'),
      PersonSourceId.fromBangumiCharacter(5),
    );
  });

  test('rejects malformed and non-positive IDs', () {
    for (final value in <String>[
      '',
      'bgm-char-0',
      'bgm-char-x',
      'bgm-anime-1',
      'bgm-char-1-extra',
    ]) {
      expect(PersonSourceId.tryParse(value), isNull);
    }
    expect(() => PersonSourceId.fromBangumiPerson(0), throwsArgumentError);
  });

  test('person and character kinds expose stable predicates', () {
    expect(PersonSourceId.fromBangumiCharacter(1).isCharacter, isTrue);
    expect(PersonSourceId.fromAniListStaff(1).isPerson, isTrue);
    expect(PersonSourceId.fromAniListStaff(1).kind, PersonEntityKind.staff);
  });
}
