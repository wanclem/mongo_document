import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:path/path.dart' as p;

final class BundledMongocLibrary {
  static const packageName = 'mongo_document_db_mongoc';

  static String directoryForAbi(Abi abi) => switch (abi) {
        Abi.linuxX64 => 'linux_x64',
        Abi.linuxArm64 => 'linux_arm64',
        Abi.macosX64 => 'macos_x64',
        Abi.macosArm64 => 'macos_arm64',
        Abi.windowsX64 => 'windows_x64',
        _ => throw UnsupportedError('Unsupported ABI: $abi'),
      };

  static String fileNameForCurrentPlatform() {
    if (Platform.isWindows) return 'mongo_document_db_mongoc.dll';
    if (Platform.isMacOS) return 'libmongo_document_db_mongoc.dylib';
    if (Platform.isLinux) return 'libmongo_document_db_mongoc.so';
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  static Future<Uri> resolveBundledLibraryUri({Abi? abi}) async {
    final dir = directoryForAbi(abi ?? Abi.current());
    final fileName = fileNameForCurrentPlatform();
    final packageUri = Uri.parse(
      'package:$packageName/src/native/$dir/$fileName',
    );

    final resolved = await Isolate.resolvePackageUri(packageUri);
    if (resolved == null) {
      throw StateError('Could not resolve $packageUri');
    }
    return resolved;
  }

  static Future<String> resolveBundledLibraryPath({Abi? abi}) async {
    final uri = await resolveBundledLibraryUri(abi: abi);
    final path = uri.toFilePath();
    if (!File(path).existsSync()) {
      final dir = p.dirname(path);
      throw StateError(
        'Native library not found at $path. '
        'Build it and place the output in $dir.',
      );
    }
    return path;
  }
}

