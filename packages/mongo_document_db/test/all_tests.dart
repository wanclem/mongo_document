@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';

import 'database_test.dart' as database;
import 'gridfs_test.dart' as gridfs;
import 'packet_converter_test.dart' as converter;
import 'mongo_dart_query_test.dart' as mongo_dart_query;
import 'auth_tests/authentication_test.dart' as auth_tests;
//import 'ssl_connection_test.dart' as ssl_tests;
import 'utils_test.dart' as utils_tests;
import 'decimal_test.dart' as decimal;
import 'message_test.dart' as message;
import 'op_msg_bulk_operation_test.dart' as bulk;
import 'op_msg_collection_test.dart' as collection;
import 'op_msg_commands_test.dart' as commands;
import 'op_msg_read_operation_test.dart' as read_op;
import 'op_msg_write_operation_test.dart' as write_op;
import 'write_concern_resilience_test.dart' as write_concern_resilience;
import 'connection_manager_recovery_policy_test.dart'
    as connection_manager_recovery;
import 'db_recovery_retry_test.dart' as db_recovery_retry;
import 'recoverable_error_classifier_test.dart' as recoverable_error_classifier;
import 'server_config_pooling_test.dart' as server_config_pooling;

//import 'replica_tests.dart' as replica;

void main() {
  converter.main();
  database.main();
  gridfs.main();
  mongo_dart_query.main();
  auth_tests.main();
  //ssl_tests.main();
  utils_tests.main();
  //replica.main();
  decimal.main();
  message.main();
  bulk.main();
  collection.main();
  commands.main();
  read_op.main();
  write_op.main();
  write_concern_resilience.main();
  connection_manager_recovery.main();
  db_recovery_retry.main();
  recoverable_error_classifier.main();
  server_config_pooling.main();
}
