import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'mongo_document_generator.dart';

/// Exposes our generator as a `build_runner` builder.
Builder mongoDocumentBuilder(BuilderOptions options) => PartBuilder(
  [MongoDocumentGenerator()],
  '.mongo_document.dart',
  header: '''
  // coverage:ignore-file
  // GENERATED CODE - DO NOT MODIFY BY HAND
  // Author: Wan Clem <wannclem@gmail.com>
  ''',
  options: options,
);
