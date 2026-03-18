import 'dart:ffi';
import 'dart:io';

import 'package:mongo_document_db_driver/src/native/rust_bindings.dart';
import 'package:mongo_document_db_driver/src/native/rust_library.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('platformLibraryName returns a platform-specific filename', () {
    final name = MongoRustLibrary.platformLibraryName();

    if (Platform.isMacOS) {
      expect(name, equals('libmongo_document_db_driver_rust.dylib'));
    } else if (Platform.isLinux) {
      expect(name, equals('libmongo_document_db_driver_rust.so'));
    } else if (Platform.isWindows) {
      expect(name, equals('mongo_document_db_driver_rust.dll'));
    } else {
      fail('Unexpected platform for test: ${Platform.operatingSystem}');
    }
  });

  test('platformFolderName maps supported ABIs to prebuilt folders', () {
    expect(
      MongoRustLibrary.platformFolderName(abi: Abi.macosArm64),
      equals('macos-arm64'),
    );
    expect(
      MongoRustLibrary.platformFolderName(abi: Abi.macosX64),
      equals('macos-x64'),
    );
    expect(
      MongoRustLibrary.platformFolderName(abi: Abi.linuxX64),
      equals('linux-x64'),
    );
    expect(
      MongoRustLibrary.platformFolderName(abi: Abi.windowsX64),
      equals('windows-x64'),
    );
  });

  test('bundledLibraryPath is rooted under native/prebuilt/<os>-<arch>', () {
    final path = MongoRustLibrary.bundledLibraryPath(
      packageRoot: '/tmp/mongo_document_db_driver',
      abi: Abi.macosArm64,
    );

    expect(
      path,
      contains(
        'native${Platform.pathSeparator}prebuilt${Platform.pathSeparator}'
        'macos-arm64${Platform.pathSeparator}',
      ),
    );
    expect(
      path,
      endsWith(
        MongoRustLibrary.platformLibraryName(abi: Abi.macosArm64),
      ),
    );
  });

  test('release prebuilt artifacts exist for shipped platforms', () {
    final packageRoot = _resolvePackageRoot();

    expect(
      File(
        MongoRustLibrary.bundledLibraryPath(
          packageRoot: packageRoot,
          abi: Abi.macosArm64,
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        MongoRustLibrary.bundledLibraryPath(
          packageRoot: packageRoot,
          abi: Abi.linuxX64,
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        MongoRustLibrary.bundledLibraryPath(
          packageRoot: packageRoot,
          abi: Abi.windowsX64,
        ),
      ).existsSync(),
      isTrue,
    );
  });

  test('native assets manifest is generated for the current package', () {
    final packageRoot = _resolvePackageRoot();
    final manifestFile = File(
      p.join(packageRoot, '.dart_tool', 'native_assets.yaml'),
    );

    expect(manifestFile.existsSync(), isTrue);
    expect(
      manifestFile.readAsStringSync(),
      contains('package:mongo_document_db_driver/src/native/rust_exports.dart'),
    );
  });

  test('native asset bindings are loadable on the current platform', () {
    if (!MongoRustBindings.isAvailable()) {
      fail('Expected the bundled Rust native asset to be available.');
    }

    final bindings = MongoRustBindings.open();
    expect(bindings.abiVersion(), equals(MongoRustBindings.currentAbiVersion));
  });
}

String _resolvePackageRoot() {
  final current = Directory.current.path;
  if (p.basename(current) == 'mongo_document_db_driver') {
    return current;
  }

  final nested = p.join(current, 'packages', 'mongo_document_db_driver');
  if (Directory(nested).existsSync()) {
    return nested;
  }

  throw StateError('Unable to locate the mongo_document_db_driver package root from $current.');
}
