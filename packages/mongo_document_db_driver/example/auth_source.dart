import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

void main() async {
  var db = Db('mongodb://user:pencil@localhost/auth2?authSource=admin');
  await db.open();
  var collection = db.collection('test');
  print(await collection.find().toList());
  await db.close();
}
