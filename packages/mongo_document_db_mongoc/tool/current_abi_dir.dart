import 'dart:ffi';

void main() {
  final dir = switch (Abi.current()) {
    Abi.linuxX64 => 'linux_x64',
    Abi.linuxArm64 => 'linux_arm64',
    Abi.macosX64 => 'macos_x64',
    Abi.macosArm64 => 'macos_arm64',
    Abi.windowsX64 => 'windows_x64',
    _ => throw UnsupportedError('Unsupported ABI: ${Abi.current()}'),
  };

  print(dir);
}

