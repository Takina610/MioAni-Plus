import 'dart:io';

import 'src/lcov_coverage.dart';

const double _defaultMinimumPercentage = 80;
const String _defaultLcovPath = 'coverage/lcov.info';

void main(List<String> arguments) {
  final configuration = _parseArguments(arguments);
  final lcovFile = File(configuration.path);
  if (!lcovFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${configuration.path}');
    exitCode = 2;
    return;
  }

  final summary = parseLcov(lcovFile.readAsStringSync());
  if (summary.foundLines == 0) {
    stderr.writeln(
      'No non-generated Dart lines found in ${configuration.path}.',
    );
    exitCode = 2;
    return;
  }

  stdout.writeln(
    'Coverage: ${summary.hitLines}/${summary.foundLines} lines '
    '(${summary.percentage.toStringAsFixed(2)}%), '
    'minimum ${configuration.minimumPercentage.toStringAsFixed(2)}%.',
  );
  stdout.writeln('Included sources: ${summary.sources.length}.');

  if (!summary.meets(configuration.minimumPercentage)) {
    stderr.writeln('Coverage threshold not met.');
    exitCode = 1;
  }
}

_CoverageConfiguration _parseArguments(List<String> arguments) {
  var path = _defaultLcovPath;
  var minimumPercentage = _defaultMinimumPercentage;

  for (final argument in arguments) {
    if (argument.startsWith('--minimum=')) {
      final value = double.tryParse(argument.substring('--minimum='.length));
      if (value == null || value < 0 || value > 100) {
        throw ArgumentError.value(
          argument,
          '--minimum',
          'must be from 0 to 100',
        );
      }
      minimumPercentage = value;
    } else if (argument.startsWith('--')) {
      throw ArgumentError.value(argument, 'argument', 'is not supported');
    } else {
      path = argument;
    }
  }

  return _CoverageConfiguration(
    path: path,
    minimumPercentage: minimumPercentage,
  );
}

class _CoverageConfiguration {
  const _CoverageConfiguration({
    required this.path,
    required this.minimumPercentage,
  });

  final String path;
  final double minimumPercentage;
}
