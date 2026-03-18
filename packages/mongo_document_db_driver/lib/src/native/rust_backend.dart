import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:bson/src/types/bson_map.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/count/count_options.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/count/count_result.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/distinct/distinct_options.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/distinct/distinct_result.dart';
import 'package:mongo_document_db_driver/src/database/commands/query_and_write_operation_commands/return_classes/abstract_write_result.dart';
import 'package:mongo_document_db_driver/src/database/utils/recoverable_error_classifier.dart';

import 'rust_bindings.dart';
import 'rust_worker.dart';

final class _RustCursorBatch {
  const _RustCursorBatch(this.documents, {required this.exhausted});

  final List<Map<String, dynamic>> documents;
  final bool exhausted;
}

final class _MongoRustCursorStreamHandle {
  _MongoRustCursorStreamHandle(this._backend, this._handle);

  final MongoRustBackend _backend;
  final RustWorkerCursorHandle _handle;
  bool _closed = false;

  Stream<Map<String, dynamic>> stream() async* {
    try {
      while (true) {
        final batch = await _nextBatch();
        if (batch.documents.isNotEmpty) {
          yield* Stream<Map<String, dynamic>>.fromIterable(batch.documents);
        }
        if (batch.exhausted || batch.documents.isEmpty) {
          break;
        }
      }
    } finally {
      await close();
    }
  }

  Future<_RustCursorBatch> _nextBatch() {
    if (_closed) {
      return Future<_RustCursorBatch>.value(
        const _RustCursorBatch(<Map<String, dynamic>>[], exhausted: true),
      );
    }

    return _backend._runGuarded(() async {
      final result = await _handle.worker.nextCursorBatch(_handle.cursorId);
      final exhausted = result['exhausted'] == true;
      final bytes = MongoRustBackend._extractTransferBytes(result['resultData']);
      final documents = bytes == null || bytes.isEmpty
          ? const <Map<String, dynamic>>[]
          : MongoRustBackend._decodeBsonDocumentList(bytes);
      return _RustCursorBatch(documents, exhausted: exhausted);
    });
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await _handle.worker.closeCursor(_handle.cursorId);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}

final class MongoRustBackend {
  MongoRustBackend._(this._workerPool);

  final RustWorkerPool _workerPool;
  final Map<int, RustWorkerClient> _commandCursorWorkers =
      <int, RustWorkerClient>{};
  bool _closed = false;
  bool _healthy = true;
  String? _lastHealthError;
  static int _debugCommandCalls = 0;
  static int _debugCursorCommandCalls = 0;

  static bool get isRuntimeAvailable => MongoRustBindings.isAvailable();

  bool get isHealthy => !_closed && _healthy && _workerPool.hasHealthyWorker;

  String? get lastHealthError => _lastHealthError ?? _workerPool.lastError;

  static Map<String, int> get debugStats => <String, int>{
    'commandCalls': _debugCommandCalls,
    'cursorCommandCalls': _debugCursorCommandCalls,
  };

  static void resetDebugStats() {
    _debugCommandCalls = 0;
    _debugCursorCommandCalls = 0;
  }

  static bool isConnectionRelatedErrorMessage(String message) {
    var normalized = message.toUpperCase();
    return RecoverableErrorClassifier.isConnectionLifecycleFailureMessage(
          message,
        ) ||
        RecoverableErrorClassifier.isPrimaryRoutingFailureMessage(message) ||
        RecoverableErrorClassifier.isAuthenticationRequiredMessage(message) ||
        normalized.contains('SERVER SELECTION') ||
        normalized.contains('NO SUITABLE SERVERS') ||
        normalized.contains('CONNECTION REFUSED') ||
        normalized.contains('POOL CLEARED') ||
        normalized.contains('NETWORK') ||
        normalized.contains('TIMEOUT') ||
        normalized.contains('TIMED OUT') ||
        normalized.contains('TOPOLOGY');
  }

  void markUnhealthy([String? reason]) {
    if (_closed) {
      return;
    }
    _healthy = false;
    _lastHealthError = reason;
  }

  void _markHealthy() {
    if (_closed) {
      return;
    }
    _healthy = true;
    _lastHealthError = null;
  }

  static bool supportsPrimaryReadPreference(ReadPreference readPreference) =>
      readPreference.mode == ReadPreferenceMode.primary;

  static bool supportsReadCommand({
    required ReadPreference readPreference,
    Map<String, Object>? rawOptions,
  }) {
    if (!supportsPrimaryReadPreference(readPreference)) {
      return false;
    }
    if (rawOptions?['readPreference'] != null) {
      return false;
    }
    return true;
  }

  static bool supportsWriteConcern({
    required Db db,
    WriteConcern? writeConcern,
  }) {
    final effective = writeConcern ?? db.writeConcern;
    final w = effective?.w;
    return w != 0 && w != -1;
  }

  static bool supportsFind({
    required ReadPreference readPreference,
    FindOptions? findOptions,
    Map<String, Object>? rawOptions,
  }) {
    if (!supportsReadCommand(
      readPreference: readPreference,
      rawOptions: rawOptions,
    )) {
      return false;
    }
    if (rawOptions?['tailable'] == true ||
        rawOptions?['awaitData'] == true ||
        rawOptions?['oplogReplay'] == true) {
      return false;
    }
    if (findOptions == null) {
      return true;
    }
    // ignore: deprecated_member_use_from_same_package
    final oplogReplay = findOptions.oplogReplay;
    return !findOptions.tailable && !findOptions.awaitData && !oplogReplay;
  }

  static bool supportsFindOne({
    required ReadPreference readPreference,
    FindOptions? findOptions,
    Map<String, Object>? rawOptions,
  }) => supportsFind(
    readPreference: readPreference,
    findOptions: findOptions,
    rawOptions: rawOptions,
  );

  static bool supportsAggregateToStream({
    required ReadPreference readPreference,
    required List<Map<String, Object>> pipeline,
    bool? explain,
    Map<String, Object>? rawOptions,
  }) {
    if (!supportsReadCommand(
      readPreference: readPreference,
      rawOptions: rawOptions,
    )) {
      return false;
    }
    if (explain == true) {
      return false;
    }
    for (final stage in pipeline) {
      if (stage.containsKey(r'$changeStream')) {
        return false;
      }
    }
    return true;
  }

  static Future<MongoRustBackend> open({
    required String connectionString,
    required String databaseName,
    Duration? connectTimeout,
    Duration? serverSelectionTimeout,
    int workerCount = 1,
  }) async {
    final workerPool = await RustWorkerPool.open(
      connectionString: connectionString,
      databaseName: databaseName,
      connectTimeout: connectTimeout,
      serverSelectionTimeout: serverSelectionTimeout,
      workerCount: workerCount,
    );
    return MongoRustBackend._(workerPool);
  }

  Future<void> ping() async {
    await _runGuarded(() async {
      final worker = _workerPool.selectWorker();
      await worker.ping();
    });
  }

  Future<Map<String, dynamic>> runCommand(Map<String, Object?> command) {
    _debugCommandCalls++;
    final requestBytes = _encodeBsonDocument(command);

    return _runGuarded(() async {
      final worker = _selectCommandWorker(command);
      final result = await worker.runCommand(requestBytes);
      final bytes = _extractTransferBytes(result['resultData']);
      if (bytes == null || bytes.isEmpty) {
        _trackCommandCursorWorker(
          worker: worker,
          command: command,
          response: const <String, dynamic>{},
        );
        return const <String, dynamic>{};
      }
      final response = _decodeBsonDocument(bytes);
      _trackCommandCursorWorker(
        worker: worker,
        command: command,
        response: response,
      );
      return response;
    });
  }

  Future<Map<String, dynamic>> _executeCollectionAction(
    Map<String, Object?> request,
  ) {
    _debugCommandCalls++;
    final requestBytes = _encodeBsonDocument(request);

    return _runGuarded(() async {
      final worker = _workerPool.selectWorker();
      final result = await worker.executeCollectionAction(requestBytes);
      final bytes = _extractTransferBytes(result['resultData']);
      if (bytes == null || bytes.isEmpty) {
        return const <String, dynamic>{};
      }
      return _decodeBsonDocument(bytes);
    });
  }

  Future<List<Map<String, dynamic>>> runCursorCommand(
    Map<String, Object?> command,
  ) {
    _debugCursorCommandCalls++;
    final requestBytes = _encodeBsonDocument(command);

    return _runGuarded(() async {
      final worker = _workerPool.selectWorker();
      final result = await worker.runCursorCommand(requestBytes);
      final bytes = _extractTransferBytes(result['resultData']);
      if (bytes == null || bytes.isEmpty) {
        return const <Map<String, dynamic>>[];
      }
      return _decodeBsonDocumentList(bytes);
    });
  }

  Future<_MongoRustCursorStreamHandle> _openCursor(
    Map<String, Object?> command,
    Future<RustWorkerCursorHandle> Function(
      RustWorkerClient worker,
      Uint8List requestBytes,
    )
    opener,
  ) {
    _debugCursorCommandCalls++;
    final requestBytes = _encodeBsonDocument(command);

    return _runGuarded(() async {
      final worker = _workerPool.selectWorker();
      final cursor = await opener(worker, requestBytes);
      return _MongoRustCursorStreamHandle(this, cursor);
    });
  }

  Future<Map<String, dynamic>?> findOne({
    required String collectionName,
    Map<String, dynamic>? filter,
    Map<String, Object>? projection,
    Map<String, Object>? sort,
    String? hint,
    Map<String, Object>? hintDocument,
    int skip = 0,
    FindOptions? findOptions,
    Map<String, Object>? rawOptions,
  }) {
    final request = <String, Object?>{
      'collection': collectionName,
      if (filter != null) 'filter': filter,
      if (sort != null) 'sort': sort,
      if (projection != null) 'projection': projection,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
      if (skip > 0) 'skip': skip,
    };
    _mergeCommandOptions(request, findOptions?.options);
    _mergeCommandOptions(request, rawOptions);
    final requestBytes = _encodeBsonDocument(request);

    return _runGuarded(() async {
      final worker = _workerPool.selectWorker();
      final result = await worker.findOne(requestBytes);
      if (result['found'] != true) {
        return null;
      }
      final bytes = _extractTransferBytes(result['resultData']);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return _decodeBsonDocument(bytes);
    });
  }

  Stream<Map<String, dynamic>> findToStream({
    required String collectionName,
    Map<String, dynamic>? filter,
    Map<String, Object>? sort,
    Map<String, Object>? projection,
    String? hint,
    Map<String, Object>? hintDocument,
    int? skip,
    int? limit,
    FindOptions? findOptions,
    Map<String, Object>? rawOptions,
  }) async* {
    final request = <String, Object?>{
      'collection': collectionName,
      if (filter != null) 'filter': filter,
      if (sort != null) 'sort': sort,
      if (projection != null) 'projection': projection,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
      if (skip != null && skip > 0) 'skip': skip,
      if (limit != null && limit > 0) 'limit': limit,
    };
    _mergeCommandOptions(request, findOptions?.options);
    _mergeCommandOptions(request, rawOptions);
    final cursor = await _openCursor(
      request,
      (worker, requestBytes) => worker.openFindCursor(requestBytes),
    );
    yield* cursor.stream();
  }

  Stream<Map<String, dynamic>> aggregateToStream({
    required Db db,
    required String collectionName,
    required List<Map<String, Object>> pipeline,
    bool? explain,
    Map<String, Object>? cursorOptions,
    String? hint,
    Map<String, Object>? hintDocument,
    AggregateOptions? aggregateOptions,
    Map<String, Object>? rawOptions,
  }) async* {
    final request = <String, Object?>{
      'collection': collectionName,
      'pipeline': pipeline,
      if (explain == true) 'explain': true,
      if (cursorOptions != null) 'cursor': cursorOptions,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
    };
    _mergeCommandOptions(request, aggregateOptions?.getOptions(db));
    _mergeCommandOptions(request, rawOptions);
    final cursor = await _openCursor(
      request,
      (worker, requestBytes) => worker.openAggregateCursor(requestBytes),
    );
    yield* cursor.stream();
  }

  Future<WriteResult> insertOne({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> document,
    WriteConcern? writeConcern,
    bool? bypassDocumentValidation,
  }) async {
    document['_id'] ??= ObjectId();
    final request = <String, Object?>{
      'action': 'insertOne',
      'collection': collectionName,
      'document': document,
      if (bypassDocumentValidation == true) 'bypassDocumentValidation': true,
    };
    _mergeCommandOptions(request, _writeConcernCommand(db, writeConcern));
    final result = await _executeCollectionAction(request);
    return WriteResult.fromMap(WriteCommandType.insert, result)
      ..id = document['_id']
      ..document = document;
  }

  Future<BulkWriteResult> insertMany({
    required Db db,
    required String collectionName,
    required List<Map<String, dynamic>> documents,
    WriteConcern? writeConcern,
    bool? ordered,
    bool? bypassDocumentValidation,
  }) async {
    if (documents.isEmpty) {
      throw ArgumentError('At least one document required in insertMany');
    }
    final ids = <Object?>[];
    for (final document in documents) {
      document['_id'] ??= ObjectId();
      ids.add(document['_id']);
    }
    final request = <String, Object?>{
      'action': 'insertMany',
      'collection': collectionName,
      'documents': documents,
      if (ordered == false) 'ordered': false,
      if (bypassDocumentValidation == true) 'bypassDocumentValidation': true,
    };
    _mergeCommandOptions(request, _writeConcernCommand(db, writeConcern));
    final result = await _executeCollectionAction(request);
    return BulkWriteResult.fromMap(WriteCommandType.insert, result)
      ..ids = ids
      ..documents = documents;
  }

  Future<Map<String, dynamic>> modernUpdateCommand({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    required Object update,
    bool? upsert,
    bool? multi,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    List<dynamic>? arrayFilters,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    final request = <String, Object?>{
      'action': multi == true ? 'updateMany' : 'updateOne',
      'collection': collectionName,
      'filter': selector,
      'update': update,
      if (upsert == true) 'upsert': true,
      if (collation != null) 'collation': collation.options,
      if (arrayFilters != null) 'arrayFilters': arrayFilters,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
    };
    _mergeCommandOptions(request, _writeConcernCommand(db, writeConcern));
    return await _executeCollectionAction(request);
  }

  Future<WriteResult> replaceOne({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    required Map<String, dynamic> replacement,
    bool? upsert,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    final request = <String, Object?>{
      'action': 'replaceOne',
      'collection': collectionName,
      'filter': selector,
      'replacement': replacement,
      if (upsert == true) 'upsert': true,
      if (collation != null) 'collation': collation.options,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
    };
    _mergeCommandOptions(request, _writeConcernCommand(db, writeConcern));
    final result = await _executeCollectionAction(request);
    return WriteResult.fromMap(WriteCommandType.update, result);
  }

  Future<WriteResult> updateOne({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    required Object update,
    bool? upsert,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    List<dynamic>? arrayFilters,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    final result = await modernUpdateCommand(
      db: db,
      collectionName: collectionName,
      selector: selector,
      update: update,
      upsert: upsert,
      writeConcern: writeConcern,
      collation: collation,
      arrayFilters: arrayFilters,
      hint: hint,
      hintDocument: hintDocument,
    );
    return WriteResult.fromMap(WriteCommandType.update, result);
  }

  Future<WriteResult> updateMany({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    required Object update,
    bool? upsert,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    List<dynamic>? arrayFilters,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    final result = await modernUpdateCommand(
      db: db,
      collectionName: collectionName,
      selector: selector,
      update: update,
      upsert: upsert,
      multi: true,
      writeConcern: writeConcern,
      collation: collation,
      arrayFilters: arrayFilters,
      hint: hint,
      hintDocument: hintDocument,
    );
    return WriteResult.fromMap(WriteCommandType.update, result);
  }

  Future<WriteResult> deleteOne({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    final request = <String, Object?>{
      'action': 'deleteOne',
      'collection': collectionName,
      'filter': selector,
      if (collation != null) 'collation': collation.options,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
    };
    _mergeCommandOptions(request, _writeConcernCommand(db, writeConcern));
    final result = await _executeCollectionAction(request);
    return WriteResult.fromMap(WriteCommandType.delete, result);
  }

  Future<WriteResult> deleteMany({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    final request = <String, Object?>{
      'action': 'deleteMany',
      'collection': collectionName,
      'filter': selector,
      if (collation != null) 'collation': collation.options,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
    };
    _mergeCommandOptions(request, _writeConcernCommand(db, writeConcern));
    final result = await _executeCollectionAction(request);
    return WriteResult.fromMap(WriteCommandType.delete, result);
  }

  Future<CountResult> count({
    required String collectionName,
    Map<String, dynamic>? query,
    int? limit,
    int? skip,
    String? hint,
    Map<String, Object>? hintDocument,
    CountOptions? countOptions,
    Map<String, Object>? rawOptions,
  }) async {
    final command = <String, Object?>{
      'count': collectionName,
      if (query != null) 'query': query,
      if (limit != null && limit > 0) 'limit': limit,
      if (skip != null && skip > 0) 'skip': skip,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
    };
    _mergeCommandOptions(command, countOptions?.options);
    _mergeCommandOptions(command, rawOptions);
    final result = await runCommand(command);
    return CountResult(result);
  }

  Future<Map<String, dynamic>> distinctMap({
    required String collectionName,
    required String field,
    required Map<String, dynamic>? query,
    DistinctOptions? distinctOptions,
    Map<String, Object>? rawOptions,
  }) async {
    final command = <String, Object?>{
      'distinct': collectionName,
      'key': field,
      if (query != null) 'query': query,
    };
    _mergeCommandOptions(command, distinctOptions?.options);
    _mergeCommandOptions(command, rawOptions);
    return await runCommand(command);
  }

  Future<DistinctResult> distinct({
    required String collectionName,
    required String field,
    required Map<String, dynamic>? query,
    DistinctOptions? distinctOptions,
    Map<String, Object>? rawOptions,
  }) async {
    final result = await distinctMap(
      collectionName: collectionName,
      field: field,
      query: query,
      distinctOptions: distinctOptions,
      rawOptions: rawOptions,
    );
    return DistinctResult(result);
  }

  Future<FindAndModifyResult> findAndModify({
    required Db db,
    required String collectionName,
    Map<String, dynamic>? query,
    Map<String, Object>? sort,
    bool? remove,
    Object? update,
    bool? returnNew,
    Map<String, dynamic>? fields,
    bool? upsert,
    List? arrayFilters,
    String? hint,
    Map<String, Object>? hintDocument,
    FindAndModifyOptions? findAndModifyOptions,
    Map<String, Object>? rawOptions,
  }) async {
    final command = <String, Object?>{
      'findAndModify': collectionName,
      if (query != null) 'query': query,
      if (sort != null) 'sort': sort,
      if (remove == true) 'remove': true,
      if (update != null) 'update': update,
      if (returnNew == true) 'new': true,
      if (fields != null) 'fields': fields,
      if (upsert == true) 'upsert': true,
      if (arrayFilters != null) 'arrayFilters': arrayFilters,
      if (hint != null)
        'hint': hint
      else if (hintDocument != null)
        'hint': hintDocument,
    };
    _mergeCommandOptions(command, findAndModifyOptions?.getOptions(db));
    _mergeCommandOptions(command, rawOptions);
    final result = await runCommand(command);
    return FindAndModifyResult(result);
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _healthy = false;
    _commandCursorWorkers.clear();
    await _workerPool.close();
  }

  Future<T> _runGuarded<T>(FutureOr<T> Function() operation) async {
    if (_closed) {
      throw ConnectionException(_lastHealthError ?? 'Rust backend is closed.');
    }
    try {
      var result = await operation();
      _markHealthy();
      return result;
    } on ConnectionException catch (error) {
      if (isConnectionRelatedErrorMessage(error.message)) {
        markUnhealthy(error.message);
      }
      rethrow;
    } on Object catch (error) {
      var message = error.toString();
      if (isConnectionRelatedErrorMessage(message)) {
        markUnhealthy(message);
      }
      rethrow;
    }
  }

  static Map<String, Object?>? _writeConcernCommand(
    Db db,
    WriteConcern? writeConcern,
  ) {
    final effective = writeConcern ?? db.writeConcern;
    if (effective == null) {
      return null;
    }
    return <String, Object?>{
      'writeConcern': effective.asMap(db.writeConcernServerStatus),
    };
  }

  static void _mergeCommandOptions(
    Map<String, Object?> command,
    Map<String, Object?>? options,
  ) {
    if (options == null) {
      return;
    }
    for (final entry in options.entries) {
      command.putIfAbsent(entry.key, () => entry.value);
    }
  }

  static Uint8List _encodeBsonDocument(Map<String, Object?> document) {
    final bsonDocument = BsonMap(Map<String, dynamic>.from(document));
    final buffer = BsonBinary(bsonDocument.totalByteLength);
    bsonDocument.packValue(buffer);
    return Uint8List.fromList(buffer.byteList);
  }

  static Map<String, dynamic> _decodeBsonDocument(Uint8List bytes) {
    final buffer = BsonBinary.from(bytes);
    return Map<String, dynamic>.from(BsonMap.fromBuffer(buffer).value);
  }

  static List<Map<String, dynamic>> _decodeBsonDocumentList(Uint8List bytes) {
    final document = _decodeBsonDocument(bytes);
    final values = document['documents'];
    if (values is! List) {
      return const <Map<String, dynamic>>[];
    }

    return values
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(growable: false);
  }

  static Uint8List? _extractTransferBytes(Object? payload) {
    if (payload is TransferableTypedData) {
      return payload.materialize().asUint8List();
    }
    if (payload is Uint8List) {
      return payload;
    }
    return null;
  }

  RustWorkerClient _selectCommandWorker(Map<String, Object?> command) {
    final cursorId = _commandCursorIdFromGetMoreCommand(command);
    if (cursorId != null) {
      final pinnedWorker = _commandCursorWorkers[cursorId];
      if (pinnedWorker != null) {
        return pinnedWorker;
      }
    }
    return _workerPool.selectWorker();
  }

  void _trackCommandCursorWorker({
    required RustWorkerClient worker,
    required Map<String, Object?> command,
    required Map<String, dynamic> response,
  }) {
    final getMoreCursorId = _commandCursorIdFromGetMoreCommand(command);
    final killCursorIds = _commandCursorIdsFromKillCursorsCommand(command);

    if (killCursorIds != null) {
      for (final cursorId in killCursorIds) {
        _commandCursorWorkers.remove(cursorId);
      }
      return;
    }

    final responseCursorId = _responseCursorId(response);
    if (getMoreCursorId != null) {
      if (responseCursorId == null || responseCursorId == 0) {
        _commandCursorWorkers.remove(getMoreCursorId);
        return;
      }
      if (responseCursorId != getMoreCursorId) {
        _commandCursorWorkers.remove(getMoreCursorId);
      }
      _commandCursorWorkers[responseCursorId] = worker;
      return;
    }

    if (responseCursorId != null && responseCursorId != 0) {
      _commandCursorWorkers[responseCursorId] = worker;
    }
  }

  static int? _commandCursorIdFromGetMoreCommand(Map<String, Object?> command) {
    return switch (command['getMore']) {
      final Int64 value => value.toInt(),
      final num value => value.toInt(),
      _ => null,
    };
  }

  static List<int>? _commandCursorIdsFromKillCursorsCommand(
    Map<String, Object?> command,
  ) {
    if (command['killCursors'] == null) {
      return null;
    }
    final rawIds = command['cursors'];
    if (rawIds is! List) {
      return const <int>[];
    }
    return rawIds
        .map<int?>((value) => switch (value) {
          final Int64 int64Value => int64Value.toInt(),
          final num numericValue => numericValue.toInt(),
          _ => null,
        })
        .whereType<int>()
        .toList(growable: false);
  }

  static int? _responseCursorId(Map<String, dynamic> response) {
    final cursor = response['cursor'];
    if (cursor is! Map) {
      return null;
    }
    return switch (cursor['id']) {
      final Int64 value => value.toInt(),
      final num value => value.toInt(),
      _ => null,
    };
  }
}
