import 'dart:io';

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

void _printUsage() {
  stdout.writeln(
      'Usage: dart run tool/concurrency_probe.dart --uri <mongodb-uri> --collection <name> --id <object-id> [--workers 16] [--per-worker 50] [--warmup 20]');
}

int _percentileIndex(int length, double percentile) {
  if (length <= 0) return 0;
  final raw = (percentile * (length - 1)).round();
  if (raw < 0) return 0;
  if (raw >= length) return length - 1;
  return raw;
}

double _avg(List<int> values) {
  if (values.isEmpty) return 0;
  final total = values.fold<int>(0, (sum, value) => sum + value);
  return total / values.length;
}

Future<int> main(List<String> args) async {
  String? uri;
  String? collectionName;
  String? id;
  int workers = 16;
  int perWorker = 50;
  int warmup = 20;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String? nextValue() => i + 1 < args.length ? args[++i] : null;

    switch (arg) {
      case '--uri':
        uri = nextValue();
      case '--collection':
        collectionName = nextValue();
      case '--id':
        id = nextValue();
      case '--workers':
        workers = int.tryParse(nextValue() ?? '') ?? workers;
      case '--per-worker':
        perWorker = int.tryParse(nextValue() ?? '') ?? perWorker;
      case '--warmup':
        warmup = int.tryParse(nextValue() ?? '') ?? warmup;
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

  if (uri == null || collectionName == null || id == null) {
    _printUsage();
    return 2;
  }
  if (workers <= 0) workers = 1;
  if (perWorker <= 0) perWorker = 1;
  if (warmup < 0) warmup = 0;

  final db = await Db.create(uri);
  final objectId = ObjectId.parse(id);
  final latenciesUs = <int>[];
  final totalOps = workers * perWorker;
  var nullResults = 0;

  try {
    await db.open();
    final collection = db.collection(collectionName);
    final selector = where.id(objectId);

    for (var i = 0; i < warmup; i++) {
      await collection.findOne(selector);
    }

    final totalSw = Stopwatch()..start();
    await Future.wait(List.generate(workers, (_) async {
      for (var i = 0; i < perWorker; i++) {
        final sw = Stopwatch()..start();
        final result = await collection.findOne(selector);
        sw.stop();
        if (result == null) {
          nullResults++;
        }
        latenciesUs.add(sw.elapsedMicroseconds);
      }
    }));
    totalSw.stop();

    latenciesUs.sort();
    final p50 = latenciesUs[_percentileIndex(latenciesUs.length, 0.50)];
    final p95 = latenciesUs[_percentileIndex(latenciesUs.length, 0.95)];
    final p99 = latenciesUs[_percentileIndex(latenciesUs.length, 0.99)];
    final min = latenciesUs.first;
    final max = latenciesUs.last;
    final avg = _avg(latenciesUs);
    final totalMs = totalSw.elapsedMilliseconds;
    final throughput = totalMs > 0 ? totalOps * 1000.0 / totalMs : totalOps;

    stdout.writeln('Concurrency probe results');
    stdout.writeln(
        'workers=$workers perWorker=$perWorker warmup=$warmup totalOps=$totalOps');
    stdout.writeln('total_ms=$totalMs');
    stdout.writeln('throughput_ops_per_sec=${throughput.toStringAsFixed(2)}');
    stdout.writeln('min_us=$min');
    stdout.writeln('p50_us=$p50');
    stdout.writeln('p95_us=$p95');
    stdout.writeln('p99_us=$p99');
    stdout.writeln('max_us=$max');
    stdout.writeln('avg_us=${avg.toStringAsFixed(2)}');
    if (nullResults > 0) {
      stdout.writeln('null_results=$nullResults');
    }
  } finally {
    await db.close();
  }

  return 0;
}
