import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:mongo_document_db_driver/src/database/commands/base/command_operation.dart';

class PingCommand extends CommandOperation {
  PingCommand(Db db)
      : super(db, <String, Object>{},
            command: {'ping': 1}, disableSpeculativeReadTimeout: true);
}
