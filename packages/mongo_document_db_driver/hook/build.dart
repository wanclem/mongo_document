import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;

const _assetName = 'src/native/rust_exports.dart';
const _libraryBaseName = 'mongo_document_db_driver_rust';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final folderName = _platformFolderName(
      input.config.code.targetOS,
      input.config.code.targetArchitecture,
    );
    final libraryName = _platformLibraryName(input.config.code.targetOS);

    if (folderName == null || libraryName == null) {
      return;
    }

    final sourceFile = File.fromUri(
      input.packageRoot.resolve(
        p.join('native', 'prebuilt', folderName, libraryName),
      ),
    );

    if (!sourceFile.existsSync()) {
      return;
    }

    output.dependencies.add(sourceFile.uri);
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        file: sourceFile.uri,
        linkMode: DynamicLoadingBundled(),
      ),
    );
  });
}

String? _platformFolderName(OS os, Architecture architecture) {
  if (os == OS.macOS && architecture == Architecture.arm64) {
    return 'macos-arm64';
  }
  if (os == OS.macOS && architecture == Architecture.x64) {
    return 'macos-x64';
  }
  if (os == OS.linux && architecture == Architecture.x64) {
    return 'linux-x64';
  }
  if (os == OS.windows && architecture == Architecture.x64) {
    return 'windows-x64';
  }
  return null;
}

String? _platformLibraryName(OS os) {
  if (os == OS.macOS) {
    return 'lib$_libraryBaseName.dylib';
  }
  if (os == OS.linux) {
    return 'lib$_libraryBaseName.so';
  }
  if (os == OS.windows) {
    return '$_libraryBaseName.dll';
  }
  return null;
}
