import 'dart:ffi';
import 'dart:io';

import 'package:mongo_document_db_mongoc/mongo_document_db_mongoc.dart';
import 'package:mongo_document_db_mongoc/src/native/bundled_library.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final uri = Platform.environment['MONGODB_URI'];
  final explicitLibPath = Platform.environment['MONGO_DOCUMENT_DB_MONGOC_LIB'];

  String? skipReason;
  if (uri == null || uri.isEmpty) {
    skipReason = 'Set MONGODB_URI to run this test.';
  } else if (explicitLibPath != null &&
      explicitLibPath.isNotEmpty &&
      !File(explicitLibPath).existsSync()) {
    skipReason = 'MONGO_DOCUMENT_DB_MONGOC_LIB points to a missing file.';
  } else if (explicitLibPath == null || explicitLibPath.isEmpty) {
    final abiDir = BundledMongocLibrary.directoryForAbi(Abi.current());
    final fileName = BundledMongocLibrary.fileNameForCurrentPlatform();
    final bundledPath = p.join('lib', 'src', 'native', abiDir, fileName);
    if (!File(bundledPath).existsSync()) {
      skipReason =
          'Native library missing at $bundledPath. Run `bash tool/build_native.sh`.';
    }
  }

  test('ping returns ok', () async {
    final client = await MongocClient.connect(uri!);
    try {
      final reply = await client.ping();
      expect(reply, contains('"ok"'));
    } finally {
      await client.close();
    }
  }, skip: skipReason);
}

