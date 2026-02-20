import 'package:mongo_document_db/mongo_document_db.dart';
import 'package:mongo_document_db/src/database/commands/base/db_admin_command_operation.dart';
import 'get_all_parameters_options.dart';

class GetAllParametersCommand extends DbAdminCommandOperation {
  GetAllParametersCommand(Db db,
      {GetAllParametersOptions? getAllParametersOptions,
      Map<String, Object>? rawOptions})
      : super(db, <String, Object>{
          keyGetParameter: '*'
        }, options: <String, Object>{
          ...?getAllParametersOptions?.options,
          ...?rawOptions
        });
}
