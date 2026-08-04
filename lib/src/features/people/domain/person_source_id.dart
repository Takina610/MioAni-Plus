enum PersonEntityKind { character, person, staff }

enum PersonSource { bangumi, anilist }

final class PersonSourceId {
  const PersonSourceId._({
    required this.source,
    required this.kind,
    required this.rawId,
  });
  final PersonSource source;
  final PersonEntityKind kind;
  final int rawId;

  String get value {
    final sourcePrefix = source == PersonSource.bangumi ? 'bgm' : 'anilist';
    final kindPrefix = switch (kind) {
      PersonEntityKind.character => 'char',
      PersonEntityKind.person => 'person',
      PersonEntityKind.staff => 'staff',
    };
    return '$sourcePrefix-$kindPrefix-$rawId';
  }

  bool get isCharacter => kind == PersonEntityKind.character;
  bool get isPerson =>
      kind == PersonEntityKind.person || kind == PersonEntityKind.staff;

  static PersonSourceId? tryParse(String value) {
    final match = RegExp(
      r'^(bgm|anilist)-(char|character|person|staff)-([1-9][0-9]*)$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final rawId = int.tryParse(match.group(3)!);
    if (rawId == null || rawId <= 0) return null;
    final source = match.group(1) == 'bgm'
        ? PersonSource.bangumi
        : PersonSource.anilist;
    final kind = switch (match.group(2)) {
      'char' || 'character' => PersonEntityKind.character,
      'person' => PersonEntityKind.person,
      'staff' => PersonEntityKind.staff,
      _ => null,
    };
    return kind == null
        ? null
        : PersonSourceId._(source: source, kind: kind, rawId: rawId);
  }

  static PersonSourceId fromBangumiCharacter(int rawId) =>
      _create(PersonSource.bangumi, PersonEntityKind.character, rawId);
  static PersonSourceId fromBangumiPerson(int rawId) =>
      _create(PersonSource.bangumi, PersonEntityKind.person, rawId);
  static PersonSourceId fromAniListCharacter(int rawId) =>
      _create(PersonSource.anilist, PersonEntityKind.character, rawId);
  static PersonSourceId fromAniListStaff(int rawId) =>
      _create(PersonSource.anilist, PersonEntityKind.staff, rawId);

  static PersonSourceId _create(
    PersonSource source,
    PersonEntityKind kind,
    int rawId,
  ) {
    if (rawId <= 0) throw ArgumentError.value(rawId, 'rawId');
    return PersonSourceId._(source: source, kind: kind, rawId: rawId);
  }

  @override
  bool operator ==(Object other) =>
      other is PersonSourceId &&
      other.source == source &&
      other.kind == kind &&
      other.rawId == rawId;
  @override
  int get hashCode => Object.hash(source, kind, rawId);
  @override
  String toString() => value;
}
