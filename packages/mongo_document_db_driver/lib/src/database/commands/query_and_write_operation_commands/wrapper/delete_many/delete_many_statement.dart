import 'package:mongo_document_db_driver/src/database/commands/query_and_write_operation_commands/delete_operation/delete_statement.dart';

class DeleteManyStatement extends DeleteStatement {
  DeleteManyStatement(super.filter,
      {super.collation, super.hint, super.hintDocument})
      : super(limit: 0);
}
