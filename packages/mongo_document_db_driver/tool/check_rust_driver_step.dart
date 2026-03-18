import 'dart:io';

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:mongo_document_db_driver/src/native/rust_bindings.dart';
import 'package:mongo_document_db_driver/src/native/rust_library.dart';

Future<void> main(List<String> args) async {
  final step = args.isEmpty ? 'load' : args.first;
  stdout.writeln('step=$step:start');

  if (step == 'libraryOpen') {
    MongoRustLibrary.open();
    stdout.writeln('library=open');
    return;
  }

  if (step == 'resolveRoot') {
    stdout.writeln('root=${MongoRustLibrary.resolvePackageRoot()}');
    return;
  }

  if (step == 'libraryPath') {
    stdout.writeln('path=${MongoRustLibrary.bundledLibraryPath()}');
    return;
  }

  if (step == 'bindingsOpen') {
    MongoRustBindings.open();
    stdout.writeln('bindings=open');
    return;
  }

  if (step == 'abi') {
    final bindings = MongoRustBindings.open();
    stdout.writeln('abi=${bindings.abiVersion()}');
    return;
  }

  if (step == 'load') {
    stdout.writeln('available=${MongoRustBindings.isAvailable()}');
    return;
  }

  const uri =
      'mongodb+srv://agana:Le54snFoefZA9gvf@cluster0.nk509tk.mongodb.net/agama?retryWrites=true&w=majority&authSource=admin';

  if (step == 'create') {
    final db = await Db.create(uri);
    stdout.writeln('db=${db.databaseName}');
    return;
  }

  if (step == 'open') {
    final db = await Db.create(uri);
    await db.open();
    stdout.writeln('open=ok');
    await db.close();
    return;
  }

  if (step == 'findOne') {
    final db = await Db.create(uri);
    await db.open();
    final infos = await db.getCollectionInfos();
    stdout.writeln('collections=${infos.length}');
    await db.close();
    return;
  }

  if (step == 'selectorLimit') {
    final selector = where.sortBy('_id').limit(10);
    stdout.writeln('paramLimit=${selector.paramLimit}');
    stdout.writeln('map=${selector.map}');
    return;
  }

  stderr.writeln('unknown step=$step');
  exitCode = 2;
}
