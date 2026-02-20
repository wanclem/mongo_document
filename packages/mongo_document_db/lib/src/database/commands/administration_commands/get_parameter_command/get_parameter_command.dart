import 'package:mongo_document_db/mongo_document_db.dart';
import 'package:mongo_document_db/src/database/commands/base/db_admin_command_operation.dart';
import 'get_parameter_options.dart';

class GetParameterCommand extends DbAdminCommandOperation {
  GetParameterCommand(Db db, String parameterName,
      {GetParameterOptions? getParameterOptions,
      Map<String, Object>? rawOptions})
      : super(db, <String, Object>{
          keyGetParameter: 1,
          parameterName: 1
        }, options: <String, Object>{
          ...?getParameterOptions?.options,
          ...?rawOptions
        });
}
