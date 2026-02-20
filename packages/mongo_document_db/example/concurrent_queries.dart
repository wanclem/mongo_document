import 'package:mongo_document_db/mongo_document_db.dart';

const concurrentQueries = 3;
const dbName = 'mongo-dart-example';
const dbAddress = '127.0.0.1';

const defaultUri = 'mongodb://$dbAddress:27017/$dbName';
// Pass a real Atlas URI at runtime:
// dart run -DMONGO_DOCUMENT_ATLAS_URI='mongodb+srv://...' example/concurrent_queries.dart
const defaultUri2 = String.fromEnvironment('MONGO_DOCUMENT_ATLAS_URI');

void main() async {
  final connectionUri = defaultUri2.isEmpty ? defaultUri : defaultUri2;
  final db = await Db.create(connectionUri);
  final requiresTls = connectionUri.startsWith('mongodb+srv://') ||
      connectionUri.contains('tls=true') ||
      connectionUri.contains('ssl=true');
  await db.open(secure: requiresTls);
  final collection = db.collection('test_collection');

  var result = await Future.wait([
    collection.find().toList(),
    collection.find().toList(),
    collection.find().toList(),
    collection.find().toList(),
    collection.find().toList(),
  ]);
  print(" -");
  print(result);

  await db.close();
}
