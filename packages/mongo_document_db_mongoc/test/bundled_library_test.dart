import 'dart:ffi';

import 'package:mongo_document_db_mongoc/src/native/bundled_library.dart';
import 'package:test/test.dart';

void main() {
  test('directoryForAbi maps known ABIs', () {
    expect(BundledMongocLibrary.directoryForAbi(Abi.linuxX64), 'linux_x64');
    expect(BundledMongocLibrary.directoryForAbi(Abi.linuxArm64), 'linux_arm64');
    expect(BundledMongocLibrary.directoryForAbi(Abi.macosX64), 'macos_x64');
    expect(BundledMongocLibrary.directoryForAbi(Abi.macosArm64), 'macos_arm64');
    expect(BundledMongocLibrary.directoryForAbi(Abi.windowsX64), 'windows_x64');
  });
}

