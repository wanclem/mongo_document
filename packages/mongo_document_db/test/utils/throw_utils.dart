import 'package:mongo_document_db/mongo_document_db.dart' show MongoDartError;
import 'package:test/test.dart' show throwsA;

var throwsMongoDartError = throwsA((e) => e is MongoDartError);
