import 'package:mongo_document_db/mongo_document_db.dart';
import 'package:test/test.dart';

void main() {
  test('retains last known capability flags without a master connection', () {
    var db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');

    var manager = ConnectionManager(db,
        lastMasterSupportsOpMsg: true,
        lastMasterSupportsListCollections: true,
        lastMasterSupportsListIndexes: true);

    expect(manager.supportsOpMsg, isTrue);
    expect(manager.supportsListCollections, isTrue);
    expect(manager.supportsListIndexes, isTrue);
  });
}
