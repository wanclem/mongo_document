import 'dart:ffi';
import 'dart:io';

import 'package:mongo_document_db_driver/src/native/rust_library.dart';
import 'package:path/path.dart' as p;

final _abiByFolder = <String, Abi>{
  'linux-arm': Abi.linuxArm,
  'linux-arm64': Abi.linuxArm64,
  'linux-ia32': Abi.linuxIA32,
  'linux-riscv32': Abi.linuxRiscv32,
  'linux-riscv64': Abi.linuxRiscv64,
  'linux-x64': Abi.linuxX64,
  'macos-arm64': Abi.macosArm64,
  'macos-x64': Abi.macosX64,
  'windows-arm64': Abi.windowsArm64,
  'windows-ia32': Abi.windowsIA32,
  'windows-x64': Abi.windowsX64,
};

Future<void> main(List<String> args) async {
  final packageRoot = Directory.current.path;
  final parsedArgs = _parseArgs(args);
  if (parsedArgs == null) {
    stderr.writeln(
      'Usage: dart run tool/stage_rust_prebuilt.dart '
      '[--abi=<platform-folder>] [--source=<path>]',
    );
    stderr.writeln('Example: --abi=linux-x64 --source=/tmp/libmongo_document_db_driver_rust.so');
    exitCode = 64;
    return;
  }

  final abi = parsedArgs.abi;
  final fileName = MongoRustLibrary.platformLibraryName(abi: abi);
  final sourcePath =
      parsedArgs.sourcePath ??
      p.join(packageRoot, 'native', 'rust', 'target', 'release', fileName);
  final targetPath = p.join(
    packageRoot,
    'native',
    'prebuilt',
    MongoRustLibrary.platformFolderName(abi: abi),
    fileName,
  );

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Rust library not found at $sourcePath');
    exitCode = 1;
    return;
  }

  final targetFile = File(targetPath);
  await targetFile.parent.create(recursive: true);
  await sourceFile.copy(targetFile.path);
  stdout.writeln('Staged Rust library to ${targetFile.path}');
}

_StageArgs? _parseArgs(List<String> args) {
  Abi abi = Abi.current();
  String? sourcePath;

  for (final arg in args) {
    if (arg.startsWith('--abi=')) {
      final folderName = arg.substring('--abi='.length);
      final parsedAbi = _abiByFolder[folderName];
      if (parsedAbi == null) {
        stderr.writeln('Unsupported abi folder: $folderName');
        return null;
      }
      abi = parsedAbi;
      continue;
    }

    if (arg.startsWith('--source=')) {
      sourcePath = p.normalize(arg.substring('--source='.length));
      continue;
    }

    if (arg.startsWith('--')) {
      stderr.writeln('Unknown option: $arg');
      return null;
    }

    if (sourcePath != null) {
      stderr.writeln('Unexpected extra positional argument: $arg');
      return null;
    }
    sourcePath = p.normalize(arg);
  }

  return _StageArgs(abi: abi, sourcePath: sourcePath);
}

class _StageArgs {
  const _StageArgs({required this.abi, required this.sourcePath});

  final Abi abi;
  final String? sourcePath;
}
