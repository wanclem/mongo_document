import 'package:mongo_document_db/mongo_document_db.dart';
import 'package:mongo_document_db/src/database/commands/query_and_write_operation_commands/insert_operation/insert_options.dart';
import 'package:test/test.dart';

void main() {
  test('write concern options do not require an active master connection', () {
    var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
    db.state = State.open;

    var options =
        InsertOptions(writeConcern: WriteConcern.acknowledged).getOptions(db);

    expect(options, contains(keyWriteConcern));
    expect(options[keyWriteConcern], isA<Map<String, Object>>());
  });

  test('writeConcernServerStatus has a safe fallback', () {
    var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
    db.state = State.open;

    var status = db.writeConcernServerStatus;

    expect(status.isPersistent, isTrue);
  });
}
