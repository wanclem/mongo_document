import 'dart:async';

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/count/count_options.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/count/count_result.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/distinct/distinct_options.dart';
import 'package:mongo_document_db_driver/src/database/commands/aggregation_commands/distinct/distinct_result.dart';
import 'package:mongo_document_db_driver/src/database/utils/recoverable_error_classifier.dart';

final class MongoRustBackend {
  MongoRustBackend._();

  static const String _unsupportedMessage =
      'MongoDB Rust backend is unavailable on this platform.';

  static bool get isRuntimeAvailable => false;

  bool get isHealthy => false;

  String? get lastHealthError => _unsupportedMessage;

  static Map<String, int> get debugStats => const <String, int>{
    'commandCalls': 0,
    'cursorCommandCalls': 0,
  };

  static void resetDebugStats() {}

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

  void markUnhealthy([String? reason]) {}

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
    throw const ConnectionException(_unsupportedMessage);
  }

  Future<void> ping() async => _throwUnsupported();

  Future<Map<String, dynamic>> runCommand(Map<String, Object?> command) async =>
      _throwUnsupported();

  Future<List<Map<String, dynamic>>> runCursorCommand(
    Map<String, Object?> command,
  ) async => _throwUnsupported();

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
  }) async => _throwUnsupported();

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
  }) => Stream<Map<String, dynamic>>.error(
    const ConnectionException(_unsupportedMessage),
  );

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
  }) => Stream<Map<String, dynamic>>.error(
    const ConnectionException(_unsupportedMessage),
  );

  Future<WriteResult> insertOne({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> document,
    WriteConcern? writeConcern,
    bool? bypassDocumentValidation,
  }) async => _throwUnsupported();

  Future<BulkWriteResult> insertMany({
    required Db db,
    required String collectionName,
    required List<Map<String, dynamic>> documents,
    WriteConcern? writeConcern,
    bool? ordered,
    bool? bypassDocumentValidation,
  }) async => _throwUnsupported();

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
  }) async => _throwUnsupported();

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
  }) async => _throwUnsupported();

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
  }) async => _throwUnsupported();

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
  }) async => _throwUnsupported();

  Future<WriteResult> deleteOne({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async => _throwUnsupported();

  Future<WriteResult> deleteMany({
    required Db db,
    required String collectionName,
    required Map<String, dynamic> selector,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async => _throwUnsupported();

  Future<CountResult> count({
    required String collectionName,
    Map<String, dynamic>? query,
    int? limit,
    int? skip,
    String? hint,
    Map<String, Object>? hintDocument,
    CountOptions? countOptions,
    Map<String, Object>? rawOptions,
  }) async => _throwUnsupported();

  Future<Map<String, dynamic>> distinctMap({
    required String collectionName,
    required String field,
    required Map<String, dynamic>? query,
    DistinctOptions? distinctOptions,
    Map<String, Object>? rawOptions,
  }) async => _throwUnsupported();

  Future<DistinctResult> distinct({
    required String collectionName,
    required String field,
    required Map<String, dynamic>? query,
    DistinctOptions? distinctOptions,
    Map<String, Object>? rawOptions,
  }) async => _throwUnsupported();

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
  }) async => _throwUnsupported();

  Future<void> close() async {}

  Never _throwUnsupported() {
    throw const ConnectionException(_unsupportedMessage);
  }
}
