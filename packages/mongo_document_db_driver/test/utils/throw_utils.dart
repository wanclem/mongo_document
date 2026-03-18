import 'package:mongo_document_db_driver/mongo_document_db_driver.dart' show MongoDartError;
import 'package:test/test.dart' show throwsA;

var throwsMongoDartError = throwsA((e) => e is MongoDartError);
