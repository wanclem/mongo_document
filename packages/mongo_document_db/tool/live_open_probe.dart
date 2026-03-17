import 'dart:io';

import 'package:mongo_document_db/mongo_document_db.dart';

const _slowThreshold = Duration(seconds: 3);

void _printUsage() {
  stdout.writeln(
      'Usage: MONGO_PROBE_URI=<mongodb-uri> dart run tool/live_open_probe.dart '
      '[--uri <mongodb-uri>] [--iterations 5]');
}

String _formatDuration(Duration duration) =>
    '${duration.inMilliseconds.toString()}ms';

String _slowFlag(Duration duration) =>
    duration >= _slowThreshold ? ' SLOW' : '';

int _percentileMs(List<int> sortedValues, double percentile) {
  if (sortedValues.isEmpty) {
    return 0;
  }
  final index = ((sortedValues.length - 1) * percentile).round();
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}

Future<Duration> _measure(Future<void> Function() action) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();
  return stopwatch.elapsed;
}

Future<int> main(List<String> args) async {
  String? uri = Platform.environment['MONGO_PROBE_URI'];
  var iterations = 5;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String? nextValue() => i + 1 < args.length ? args[++i] : null;
    switch (arg) {
      case '--uri':
        uri = nextValue();
      case '--iterations':
        iterations = int.tryParse(nextValue() ?? '') ?? iterations;
      case '--help':
      case '-h':
        _printUsage();
        return 0;
      default:
        if (arg.startsWith('--')) {
          stderr.writeln('Unknown option: $arg');
          _printUsage();
          return 2;
        }
    }
  }

  if (uri == null || uri.isEmpty) {
    _printUsage();
    return 2;
  }
  if (iterations <= 0) {
    iterations = 1;
  }

  final createTimings = <int>[];
  final openTimings = <int>[];

  for (var i = 1; i <= iterations; i++) {
    late Db db;
    final createElapsed = await _measure(() async {
      db = await Db.create(uri!);
    });
    createTimings.add(createElapsed.inMilliseconds);
    stdout
        .writeln('[OK] iteration $i Db.create ${_formatDuration(createElapsed)}'
            '${_slowFlag(createElapsed)}');

    try {
      final openElapsed = await _measure(() async {
        await db.open();
      });
      openTimings.add(openElapsed.inMilliseconds);
      stdout.writeln('[OK] iteration $i db.open ${_formatDuration(openElapsed)}'
          '${_slowFlag(openElapsed)}');
    } catch (error) {
      stdout.writeln('[ERR] iteration $i db.open error=$error');
      rethrow;
    } finally {
      try {
        await db.close();
      } catch (_) {}
    }
  }

  createTimings.sort();
  openTimings.sort();
  stdout.writeln('Summary:');
  stdout.writeln(
      '  Db.create avg=${_formatDuration(Duration(milliseconds: (createTimings.fold<int>(0, (sum, value) => sum + value) ~/ createTimings.length)))} '
      'p95=${_formatDuration(Duration(milliseconds: _percentileMs(createTimings, 0.95)))} '
      'max=${_formatDuration(Duration(milliseconds: createTimings.last))}');
  stdout.writeln(
      '  db.open avg=${_formatDuration(Duration(milliseconds: (openTimings.fold<int>(0, (sum, value) => sum + value) ~/ openTimings.length)))} '
      'p95=${_formatDuration(Duration(milliseconds: _percentileMs(openTimings, 0.95)))} '
      'max=${_formatDuration(Duration(milliseconds: openTimings.last))}');
  return 0;
}
