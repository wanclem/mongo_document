import 'dart:async';
import 'dart:io';

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

const _slowOperationThreshold = Duration(seconds: 3);
const _defaultOperationTimeout = Duration(seconds: 20);
const _probeCollectionName = '_mongo_document_codex_probe';

void _printUsage() {
  stdout.writeln(
      'Usage: MONGO_PROBE_URI=<mongodb-uri> dart run tool/live_workload_probe.dart '
      '[--uri <mongodb-uri>] [--waves 6] [--workers 16] [--per-worker 20]');
}

String _formatDuration(Duration duration) =>
    '${duration.inMilliseconds.toString()}ms';

double _averageUs(List<int> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.fold<int>(0, (sum, value) => sum + value) / values.length;
}

int _percentileUs(List<int> sortedValues, double percentile) {
  if (sortedValues.isEmpty) {
    return 0;
  }
  final index = ((sortedValues.length - 1) * percentile).round();
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}

String _slowFlag(Duration elapsed) =>
    elapsed >= _slowOperationThreshold ? ' SLOW' : '';

class _ProbeResult<T> {
  final String name;
  final Duration elapsed;
  final T? value;
  final Object? error;

  const _ProbeResult(
      {required this.name, required this.elapsed, this.value, this.error});

  bool get ok => error == null;
  bool get slow => elapsed >= _slowOperationThreshold;
}

Future<_ProbeResult<T>> _measure<T>(String name, Future<T> Function() action,
    {Duration timeout = _defaultOperationTimeout}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final value = await action().timeout(timeout);
    stopwatch.stop();
    return _ProbeResult<T>(
      name: name,
      elapsed: stopwatch.elapsed,
      value: value,
    );
  } catch (error) {
    stopwatch.stop();
    return _ProbeResult<T>(
      name: name,
      elapsed: stopwatch.elapsed,
      error: error,
    );
  }
}

bool _isScalarProbeValue(Object? value) =>
    value is String ||
    value is num ||
    value is bool ||
    value is DateTime ||
    value is ObjectId;

MapEntry<String, Object>? _pickScalarField(Map<String, dynamic> document) {
  for (final entry in document.entries) {
    if (entry.key == '_id') {
      continue;
    }
    final value = entry.value;
    if (value is String && value.length > 120) {
      continue;
    }
    if (value != null && _isScalarProbeValue(value)) {
      return MapEntry<String, Object>(entry.key, value as Object);
    }
  }
  return null;
}

SelectorBuilder _selectorForId(Object id) {
  if (id is ObjectId) {
    return where.id(id);
  }
  return where.eq('_id', id);
}

String _describeWinningPlan(Map<String, dynamic>? explainDoc) {
  if (explainDoc == null) {
    return 'unknown';
  }

  String? walk(dynamic node) {
    if (node is Map) {
      final stage = node['stage'];
      if (stage is String && stage.isNotEmpty) {
        final inputStage = walk(node['inputStage']);
        if (inputStage != null) {
          return '$stage>$inputStage';
        }
        final inputStages = node['inputStages'];
        if (inputStages is List && inputStages.isNotEmpty) {
          final firstChild = walk(inputStages.first);
          if (firstChild != null) {
            return '$stage>$firstChild';
          }
        }
        return stage;
      }
      return walk(node['queryPlanner']) ??
          walk(node['winningPlan']) ??
          walk(node['queryPlan']) ??
          walk(node['executionStages']);
    }
    return null;
  }

  return walk(explainDoc) ?? 'unknown';
}

String _stringPayload(int size) => List<String>.filled(size, 'x').join();

void _printResultLine(_ProbeResult<dynamic> result, {String? detail}) {
  final status = result.ok ? 'OK' : 'ERR';
  final suffix = detail == null || detail.isEmpty ? '' : ' $detail';
  stdout.writeln(
      '[$status] ${result.name} ${_formatDuration(result.elapsed)}${_slowFlag(result.elapsed)}$suffix');
  if (!result.ok) {
    stdout.writeln('      error=${result.error}');
  }
}

Future<void> _ignoreDrop(Db db, String collectionName) async {
  try {
    await db.dropCollection(collectionName);
  } catch (_) {}
}

Future<int> main(List<String> args) async {
  String? uri = Platform.environment['MONGO_PROBE_URI'];
  var waves = 6;
  var workers = 16;
  var perWorker = 20;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String? nextValue() => i + 1 < args.length ? args[++i] : null;
    switch (arg) {
      case '--uri':
        uri = nextValue();
      case '--waves':
        waves = int.tryParse(nextValue() ?? '') ?? waves;
      case '--workers':
        workers = int.tryParse(nextValue() ?? '') ?? workers;
      case '--per-worker':
        perWorker = int.tryParse(nextValue() ?? '') ?? perWorker;
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

  if (waves <= 0) {
    waves = 1;
  }
  if (workers <= 0) {
    workers = 1;
  }
  if (perWorker <= 0) {
    perWorker = 1;
  }

  final db = await Db.create(uri);
  final results = <_ProbeResult<dynamic>>[];
  final collectionNames = <String>[];
  String? anchorCollectionName;
  Object? anchorId;

  try {
    final openResult = await _measure<void>('db.open', () => db.open(),
        timeout: const Duration(seconds: 30));
    results.add(openResult);
    _printResultLine(openResult);
    if (!openResult.ok) {
      return 1;
    }

    final infosResult = await _measure<List<Map<String, dynamic>>>(
      'db.getCollectionInfos',
      () => db.getCollectionInfos(),
    );
    results.add(infosResult);
    if (infosResult.ok) {
      for (final info in infosResult.value!) {
        final name = info['name']?.toString();
        if (name != null && name.isNotEmpty) {
          collectionNames.add(name);
        }
      }
      _printResultLine(infosResult,
          detail: 'collections=${collectionNames.length}');
    } else {
      _printResultLine(infosResult);
    }

    final namesResult = await _measure<List<String?>>(
      'db.getCollectionNames',
      () => db.getCollectionNames(),
    );
    results.add(namesResult);
    _printResultLine(namesResult,
        detail: namesResult.ok ? 'names=${namesResult.value!.length}' : null);

    if (collectionNames.isNotEmpty) {
      stdout.writeln('Collections: ${collectionNames.join(', ')}');
    }

    for (final collectionName in collectionNames) {
      final collection = db.collection(collectionName);
      final sampleResult = await _measure<Map<String, dynamic>?>(
        'collection.$collectionName.sample.findOne',
        () => collection.findOne(),
      );
      results.add(sampleResult);

      if (!sampleResult.ok) {
        _printResultLine(sampleResult);
        continue;
      }

      final sample = sampleResult.value;
      if (sample == null) {
        _printResultLine(sampleResult, detail: 'empty');
        continue;
      }

      final sampleKeys = sample.keys.take(8).join(', ');
      _printResultLine(sampleResult, detail: 'keys=[$sampleKeys]');

      final id = sample['_id'];
      final scalarField = _pickScalarField(sample);

      if (id != null) {
        final byIdResult = await _measure<Map<String, dynamic>?>(
          'collection.$collectionName.findOneById',
          () => collection.findOne(_selectorForId(id)),
        );
        results.add(byIdResult);
        _printResultLine(byIdResult);

        final pageResult = await _measure<List<Map<String, dynamic>>>(
          'collection.$collectionName.findSortedLimit10',
          () => collection.find(where.sortBy('_id').limit(10)).toList(),
        );
        results.add(pageResult);
        _printResultLine(pageResult,
            detail: pageResult.ok ? 'docs=${pageResult.value!.length}' : null);

        if (anchorCollectionName == null &&
            !collectionName.startsWith('system.')) {
          anchorCollectionName = collectionName;
          anchorId = id;
        }
      }

      if (scalarField != null) {
        final fieldQueryResult = await _measure<List<Map<String, dynamic>>>(
          'collection.$collectionName.findEqLimit5.${scalarField.key}',
          () => collection
              .find(where.eq(scalarField.key, scalarField.value).limit(5))
              .toList(),
        );
        results.add(fieldQueryResult);
        _printResultLine(fieldQueryResult,
            detail: fieldQueryResult.ok
                ? 'docs=${fieldQueryResult.value!.length}'
                : null);

        final explainResult = await _measure<Map<String, dynamic>?>(
          'collection.$collectionName.explain.${scalarField.key}',
          () => collection.findOne(where
              .eq(scalarField.key, scalarField.value)
              .sortBy('_id')
              .limit(5)
              .explain()),
        );
        results.add(explainResult);
        _printResultLine(explainResult,
            detail: explainResult.ok
                ? 'plan=${_describeWinningPlan(explainResult.value)}'
                : null);
      } else if (id != null) {
        final explainResult = await _measure<Map<String, dynamic>?>(
          'collection.$collectionName.explainById',
          () => collection.findOne(_selectorForId(id).explain()),
        );
        results.add(explainResult);
        _printResultLine(explainResult,
            detail: explainResult.ok
                ? 'plan=${_describeWinningPlan(explainResult.value)}'
                : null);
      }

      if (id != null || scalarField != null) {
        final match = <String, Object>{
          '_id': ?id,
          if (id == null && scalarField != null)
            scalarField.key: scalarField.value,
        };
        final projection = <String, Object>{
          '_id': 1,
          if (scalarField != null) scalarField.key: 1,
        };
        final aggregateResult = await _measure<List<Map<String, dynamic>>>(
          'collection.$collectionName.aggregateMatchLimit5',
          () => collection.aggregateToStream(<Map<String, Object>>[
            <String, Object>{r'$match': match},
            <String, Object>{
              r'$sort': <String, Object>{'_id': 1}
            },
            <String, Object>{r'$limit': 5},
            <String, Object>{r'$project': projection},
          ]).toList(),
        );
        results.add(aggregateResult);
        _printResultLine(aggregateResult,
            detail: aggregateResult.ok
                ? 'docs=${aggregateResult.value!.length}'
                : null);
      }
    }

    await _ignoreDrop(db, _probeCollectionName);
    final probeCollection = db.collection(_probeCollectionName);
    final probeId = ObjectId();
    final probeDocument = <String, dynamic>{
      '_id': probeId,
      'kind': 'codex_live_probe',
      'createdAt': DateTime.now().toUtc(),
      'counter': 0,
      'payload': _stringPayload(1024),
    };

    final insertResult = await _measure<WriteResult>(
      'probe.insertOne',
      () => probeCollection.insertOne(<String, dynamic>{...probeDocument}),
    );
    results.add(insertResult);
    _printResultLine(insertResult);

    final findProbeResult = await _measure<Map<String, dynamic>?>(
      'probe.findOneById',
      () => probeCollection.findOne(where.id(probeId)),
    );
    results.add(findProbeResult);
    _printResultLine(findProbeResult);

    final updateResult = await _measure<WriteResult>(
      'probe.updateOne',
      () => probeCollection.updateOne(
          where.id(probeId),
          modify
              .set('updatedAt', DateTime.now().toUtc())
              .set('status', 'updated')
              .inc('counter', 1)),
    );
    results.add(updateResult);
    _printResultLine(updateResult);

    final findAndModifyResult = await _measure<Map<String, dynamic>?>(
      'probe.findAndModify',
      () => probeCollection.findAndModify(
        query: where.id(probeId),
        update: modify.set('touchedBy', 'live_workload_probe'),
        returnNew: true,
      ),
    );
    results.add(findAndModifyResult);
    _printResultLine(findAndModifyResult);

    final aggregateProbeResult = await _measure<List<Map<String, dynamic>>>(
      'probe.aggregateById',
      () => probeCollection.aggregateToStream(<Map<String, Object>>[
        <String, Object>{
          r'$match': <String, Object>{'_id': probeId}
        },
        <String, Object>{
          r'$project': <String, Object>{
            '_id': 1,
            'counter': 1,
            'status': 1,
            'touchedBy': 1,
          }
        },
      ]).toList(),
    );
    results.add(aggregateProbeResult);
    _printResultLine(aggregateProbeResult,
        detail: aggregateProbeResult.ok
            ? 'docs=${aggregateProbeResult.value!.length}'
            : null);

    final deleteResult = await _measure<WriteResult>(
      'probe.deleteOne',
      () => probeCollection.deleteOne(where.id(probeId)),
    );
    results.add(deleteResult);
    _printResultLine(deleteResult);

    final dropResult = await _measure<bool>(
      'probe.dropCollection',
      () => db.dropCollection(_probeCollectionName),
    );
    results.add(dropResult);
    _printResultLine(dropResult);

    if (anchorCollectionName != null && anchorId != null) {
      final anchorCollection = db.collection(anchorCollectionName);
      stdout.writeln(
          'Running sustained concurrency probe on $anchorCollectionName with '
          '$workers workers x $perWorker ops for $waves waves');
      for (var wave = 1; wave <= waves; wave++) {
        final waveResult = await _measure<Map<String, Object>>(
          'concurrency.wave$wave.$anchorCollectionName',
          () async {
            final latenciesUs = <int>[];
            final totalOps = workers * perWorker;
            final totalStopwatch = Stopwatch()..start();

            await Future.wait(List.generate(workers, (_) async {
              for (var op = 0; op < perWorker; op++) {
                final operationStopwatch = Stopwatch()..start();
                final document =
                    await anchorCollection.findOne(_selectorForId(anchorId!));
                operationStopwatch.stop();
                if (document == null) {
                  throw StateError(
                      'Anchor document disappeared during probing');
                }
                latenciesUs.add(operationStopwatch.elapsedMicroseconds);
              }
            }));

            totalStopwatch.stop();
            latenciesUs.sort();

            return <String, Object>{
              'ops': totalOps,
              'totalMs': totalStopwatch.elapsedMilliseconds,
              'avgUs': _averageUs(latenciesUs).toStringAsFixed(2),
              'p50Us': _percentileUs(latenciesUs, 0.50),
              'p95Us': _percentileUs(latenciesUs, 0.95),
              'p99Us': _percentileUs(latenciesUs, 0.99),
              'maxUs': latenciesUs.isEmpty ? 0 : latenciesUs.last,
            };
          },
          timeout: const Duration(minutes: 2),
        );
        results.add(waveResult);
        _printResultLine(waveResult,
            detail: waveResult.ok
                ? 'ops=${waveResult.value!['ops']} '
                    'p95_us=${waveResult.value!['p95Us']} '
                    'max_us=${waveResult.value!['maxUs']} '
                    'total_ms=${waveResult.value!['totalMs']}'
                : null);
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } else {
      stdout.writeln(
          'Skipping sustained concurrency probe because no non-empty collection '
          'with an _id anchor was found.');
    }
  } finally {
    await _ignoreDrop(db, _probeCollectionName);
    try {
      await db.close();
    } catch (_) {}
  }

  final slowResults = results.where((result) => result.slow).toList()
    ..sort((left, right) => right.elapsed.compareTo(left.elapsed));
  final failedResults = results.where((result) => !result.ok).toList();

  stdout.writeln('');
  stdout.writeln('Summary');
  stdout.writeln('operations=${results.length}');
  stdout.writeln('slow_operations=${slowResults.length}');
  stdout.writeln('failed_operations=${failedResults.length}');

  if (slowResults.isNotEmpty) {
    stdout.writeln('Slowest operations:');
    for (final result in slowResults.take(10)) {
      stdout.writeln(
          '  - ${result.name}: ${_formatDuration(result.elapsed)}${_slowFlag(result.elapsed)}');
    }
  }

  return failedResults.isEmpty ? 0 : 1;
}
