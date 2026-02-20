import 'package:mongo_document_db/src/database/commands/query_and_write_operation_commands/delete_operation/delete_options.dart';

class DeleteManyOptions extends DeleteOptions {
  DeleteManyOptions({super.writeConcern, super.comment});
}
