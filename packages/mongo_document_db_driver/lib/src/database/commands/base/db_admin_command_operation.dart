import 'package:mongo_document_db_driver/mongo_document_db_driver.dart' show Connection, Db;
import 'package:mongo_document_db_driver/src/database/message/mongo_modern_message.dart';
import 'package:mongo_document_db_driver/src/database/utils/map_keys.dart';

import 'operation_base.dart';

class DbAdminCommandOperation extends OperationBase {
  Db db;
  Map<String, Object> command;

  DbAdminCommandOperation(this.db, this.command,
      {Map<String, Object>? options, Connection? connection})
      : super(options, connection: connection);

  Map<String, Object> $buildCommand() => command;

  @override
  Future<Map<String, dynamic>> execute() async {
    final db = this.db;
    var command = <String, Object>{
      ...$buildCommand(),
      keyDatabaseName: 'admin'
    };
    options.removeWhere((key, value) => command.containsKey(key));

    command.addAll(options);

    var modernMessage = MongoModernMessage(command);
    return db.executeModernMessage(modernMessage, connection: connection);
  }
}
