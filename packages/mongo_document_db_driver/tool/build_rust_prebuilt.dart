import 'dart:ffi';
import 'dart:io';

import 'package:mongo_document_db_driver/src/native/rust_library.dart';
import 'package:path/path.dart' as p;

final _supportedTargets = <String, _BuildTarget>{
  'macos-arm64': _BuildTarget(
    id: 'macos-arm64',
    abi: Abi.macosArm64,
    rustTarget: 'aarch64-apple-darwin',
    useZigbuild: false,
  ),
  'macos-x64': _BuildTarget(
    id: 'macos-x64',
    abi: Abi.macosX64,
    rustTarget: 'x86_64-apple-darwin',
    useZigbuild: false,
  ),
  'linux-x64': _BuildTarget(
    id: 'linux-x64',
    abi: Abi.linuxX64,
    rustTarget: 'x86_64-unknown-linux-gnu',
    useZigbuild: true,
  ),
  'windows-x64': _BuildTarget(
    id: 'windows-x64',
    abi: Abi.windowsX64,
    rustTarget: 'x86_64-pc-windows-gnu',
    useZigbuild: true,
  ),
};

Future<void> main(List<String> args) async {
  final packageRoot = Directory.current.path;
  final targets = _resolveTargets(args);
  if (targets == null) {
    _printUsage();
    exitCode = 64;
    return;
  }

  for (final target in targets) {
    stdout.writeln('Building ${target.id} (${target.rustTarget})...');
    await _runBuild(packageRoot, target);
    await _stageOutput(packageRoot, target);
  }
}

List<_BuildTarget>? _resolveTargets(List<String> args) {
  if (args.isEmpty) {
    return [_defaultHostTarget()];
  }

  final targetIds = <String>[];
  var buildAll = false;

  for (final arg in args) {
    if (arg == '--all') {
      buildAll = true;
      continue;
    }

    if (arg.startsWith('--target=')) {
      targetIds.add(arg.substring('--target='.length));
      continue;
    }

    stderr.writeln('Unknown option: $arg');
    return null;
  }

  if (buildAll) {
    return _supportedTargets.values.toList(growable: false);
  }

  if (targetIds.isEmpty) {
    return [_defaultHostTarget()];
  }

  final resolved = <_BuildTarget>[];
  for (final id in targetIds) {
    final target = _supportedTargets[id];
    if (target == null) {
      stderr.writeln('Unsupported target: $id');
      return null;
    }
    resolved.add(target);
  }
  return resolved;
}

_BuildTarget _defaultHostTarget() {
  final hostFolder = MongoRustLibrary.platformFolderName();
  final target = _supportedTargets[hostFolder];
  if (target == null) {
    throw UnsupportedError('No default Rust build target configured for $hostFolder.');
  }
  return target;
}

Future<void> _runBuild(String packageRoot, _BuildTarget target) async {
  final home = Platform.environment['HOME'] ?? '';
  final cargoCommand = p.join(
    home,
    '.cargo',
    'bin',
    'cargo',
  );
  final manifestPath = p.join(packageRoot, 'native', 'rust', 'Cargo.toml');
  final subcommand = target.useZigbuild ? 'zigbuild' : 'build';
  final args = <String>[
    subcommand,
    '--manifest-path',
    manifestPath,
    '--release',
    '--target',
    target.rustTarget,
  ];

  final process = await Process.start(
    cargoCommand,
    args,
    workingDirectory: packageRoot,
    environment: {
      ...Platform.environment,
      'PATH': _buildPathOverrides(home),
      'CARGO_HTTP_TIMEOUT': Platform.environment['CARGO_HTTP_TIMEOUT'] ?? '600',
      'CARGO_NET_RETRY': Platform.environment['CARGO_NET_RETRY'] ?? '10',
      'CARGO_REGISTRIES_CRATES_IO_PROTOCOL':
          Platform.environment['CARGO_REGISTRIES_CRATES_IO_PROTOCOL'] ?? 'sparse',
    },
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(cargoCommand, args, 'Rust build failed.', exitCode);
  }
}

String _buildPathOverrides(String home) {
  final entries = <String>[
    if (home.isNotEmpty) p.join(home, '.cargo', 'bin'),
    '/opt/homebrew/bin',
    Platform.environment['PATH'] ?? '',
  ];
  return entries.where((entry) => entry.isNotEmpty).join(
    Platform.isWindows ? ';' : ':',
  );
}

Future<void> _stageOutput(String packageRoot, _BuildTarget target) async {
  final sourcePath = p.join(
    packageRoot,
    'native',
    'rust',
    'target',
    target.rustTarget,
    'release',
    MongoRustLibrary.platformLibraryName(abi: target.abi),
  );
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    throw FileSystemException(
      'Built Rust library not found for ${target.id}.',
      sourcePath,
    );
  }

  final targetPath = MongoRustLibrary.bundledLibraryPath(
    packageRoot: packageRoot,
    abi: target.abi,
  );
  final targetFile = File(targetPath);
  await targetFile.parent.create(recursive: true);
  await sourceFile.copy(targetFile.path);
  await _codesignIfNeeded(targetFile.path, target);
  stdout.writeln('Staged ${target.id} library to ${targetFile.path}');
}

Future<void> _codesignIfNeeded(String filePath, _BuildTarget target) async {
  if (!Platform.isMacOS) {
    return;
  }
  if (target.abi != Abi.macosArm64 && target.abi != Abi.macosX64) {
    return;
  }

  final process = await Process.start(
    'codesign',
    <String>['--force', '--sign', '-', filePath],
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(
      'codesign',
      <String>['--force', '--sign', '-', filePath],
      'Failed to ad-hoc sign staged macOS dylib.',
      exitCode,
    );
  }
}

void _printUsage() {
  stderr.writeln(
    'Usage: dart run tool/build_rust_prebuilt.dart '
    '[--target=<platform-folder>] [--target=<platform-folder>] [--all]',
  );
  stderr.writeln('Examples:');
  stderr.writeln('  dart run tool/build_rust_prebuilt.dart');
  stderr.writeln(
    '  dart run tool/build_rust_prebuilt.dart --target=linux-x64 --target=windows-x64',
  );
  stderr.writeln('  dart run tool/build_rust_prebuilt.dart --all');
}

class _BuildTarget {
  const _BuildTarget({
    required this.id,
    required this.abi,
    required this.rustTarget,
    required this.useZigbuild,
  });

  final String id;
  final Abi abi;
  final String rustTarget;
  final bool useZigbuild;
}
