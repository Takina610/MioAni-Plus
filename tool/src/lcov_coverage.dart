typedef CoverageSourceFilter = bool Function(String source);

class CoverageSummary {
  const CoverageSummary({
    required this.foundLines,
    required this.hitLines,
    required this.sources,
  });

  final int foundLines;
  final int hitLines;
  final List<String> sources;

  double get percentage {
    if (foundLines == 0) {
      return 0;
    }
    return hitLines * 100 / foundLines;
  }

  bool meets(double minimumPercentage) {
    return percentage >= minimumPercentage;
  }
}

CoverageSummary parseLcov(
  String content, {
  CoverageSourceFilter includeSource = _includeNonGeneratedDartSource,
}) {
  final linesBySource = <String, Map<int, int>>{};
  String? currentSource;

  for (final rawLine in content.split(RegExp(r'\r?\n'))) {
    if (rawLine.startsWith('SF:')) {
      final source = _normalizeSource(rawLine.substring(3));
      currentSource = includeSource(source) ? source : null;
      if (currentSource != null) {
        linesBySource.putIfAbsent(currentSource, () => <int, int>{});
      }
      continue;
    }
    if (rawLine == 'end_of_record') {
      currentSource = null;
      continue;
    }
    if (currentSource == null || !rawLine.startsWith('DA:')) {
      continue;
    }

    final fields = rawLine.substring(3).split(',');
    if (fields.length < 2) {
      throw const FormatException('Invalid DA record in LCOV input');
    }
    final lineNumber = int.tryParse(fields[0]);
    final hitCount = int.tryParse(fields[1]);
    if (lineNumber == null ||
        hitCount == null ||
        lineNumber < 1 ||
        hitCount < 0) {
      throw const FormatException('Invalid line or hit count in LCOV input');
    }

    final sourceLines = linesBySource[currentSource]!;
    final previousHits = sourceLines[lineNumber] ?? 0;
    if (hitCount > previousHits) {
      sourceLines[lineNumber] = hitCount;
    } else {
      sourceLines.putIfAbsent(lineNumber, () => hitCount);
    }
  }

  final sources = linesBySource.keys.toList()..sort();
  var foundLines = 0;
  var hitLines = 0;
  for (final source in sources) {
    final lineHits = linesBySource[source]!.values;
    foundLines += lineHits.length;
    hitLines += lineHits.where((hits) => hits > 0).length;
  }

  return CoverageSummary(
    foundLines: foundLines,
    hitLines: hitLines,
    sources: sources,
  );
}

bool _includeNonGeneratedDartSource(String source) {
  return source.startsWith('lib/') &&
      source.endsWith('.dart') &&
      !source.endsWith('.g.dart');
}

String _normalizeSource(String source) {
  final normalized = source.trim().replaceAll('\\', '/');
  if (normalized.startsWith('lib/')) {
    return normalized;
  }
  final libIndex = normalized.lastIndexOf('/lib/');
  if (libIndex >= 0) {
    return normalized.substring(libIndex + 1);
  }
  return normalized;
}
