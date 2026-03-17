import 'dart:io';

import 'package:mongo_document_db_mongoc/mongo_document_db_mongoc.dart';

Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI'];
  if (uri == null || uri.isEmpty) {
    stderr.writeln('Missing env var: MONGODB_URI');
    exitCode = 64;
    return;
  }

  final client = await MongocClient.connect(uri);
  try {
    final reply = await client.ping();
    stdout.writeln(reply);
  } finally {
    await client.close();
  }
}

