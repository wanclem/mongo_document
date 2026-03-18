import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

class MongoRustLibrary {
  MongoRustLibrary._();

  static const libraryBaseName = 'mongo_document_db_driver_rust';

  static String platformLibraryName({Abi? abi}) {
    return switch (abi ?? Abi.current()) {
      Abi.linuxArm ||
      Abi.linuxArm64 ||
      Abi.linuxIA32 ||
      Abi.linuxRiscv32 ||
      Abi.linuxRiscv64 ||
      Abi.linuxX64 => 'lib$libraryBaseName.so',
      Abi.macosArm64 || Abi.macosX64 => 'lib$libraryBaseName.dylib',
      Abi.windowsArm64 || Abi.windowsIA32 || Abi.windowsX64 =>
        '$libraryBaseName.dll',
      _ => throw UnsupportedError(
        'Rust backend is not configured for ABI ${abi ?? Abi.current()}.',
      ),
    };
  }

  static String platformFolderName({Abi? abi}) {
    return switch (abi ?? Abi.current()) {
      Abi.linuxArm => 'linux-arm',
      Abi.linuxArm64 => 'linux-arm64',
      Abi.linuxIA32 => 'linux-ia32',
      Abi.linuxRiscv32 => 'linux-riscv32',
      Abi.linuxRiscv64 => 'linux-riscv64',
      Abi.linuxX64 => 'linux-x64',
      Abi.macosArm64 => 'macos-arm64',
      Abi.macosX64 => 'macos-x64',
      Abi.windowsArm64 => 'windows-arm64',
      Abi.windowsIA32 => 'windows-ia32',
      Abi.windowsX64 => 'windows-x64',
      _ => throw UnsupportedError(
        'Rust backend is not configured for ABI ${abi ?? Abi.current()}.',
      ),
    };
  }

  static String bundledLibraryPath({String? packageRoot, Abi? abi}) {
    final root = packageRoot ?? resolvePackageRoot();
    return p.join(
      root,
      'native',
      'prebuilt',
      platformFolderName(abi: abi),
      platformLibraryName(abi: abi),
    );
  }

  static bool hasBundledLibrary({String? packageRoot, Abi? abi}) {
    return File(
      bundledLibraryPath(packageRoot: packageRoot, abi: abi),
    ).existsSync();
  }

  static String resolvePackageRoot() {
    final packageUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:mongo_document_db_driver/mongo_document_db_driver.dart'),
    );
    if (packageUri != null && packageUri.scheme == 'file') {
      final libraryPath = File.fromUri(packageUri).path;
      return p.normalize(p.dirname(p.dirname(libraryPath)));
    }

    final current = Directory.current.path;
    if (p.basename(current) == 'mongo_document_db_driver') {
      return current;
    }

    final nested = p.join(current, 'packages', 'mongo_document_db_driver');
    if (Directory(nested).existsSync()) {
      return nested;
    }

    throw StateError(
      'Unable to resolve the mongo_document_db_driver package root.',
    );
  }
}
