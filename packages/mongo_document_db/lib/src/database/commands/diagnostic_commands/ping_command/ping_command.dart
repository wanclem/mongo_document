import 'package:mongo_document_db/mongo_document_db.dart';
import 'package:mongo_document_db/src/database/commands/base/command_operation.dart';

class PingCommand extends CommandOperation {
  PingCommand(Db db) : super(db, <String, Object>{}, command: {'ping': 1});
}
