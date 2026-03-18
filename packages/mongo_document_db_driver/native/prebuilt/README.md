# Prebuilt Rust Libraries

This directory contains the shipped native libraries used by `mongo_document_db_driver`.

Current staged targets in this repo are:

- `native/prebuilt/macos-arm64/libmongo_document_db_driver_rust.dylib`
- `native/prebuilt/linux-x64/libmongo_document_db_driver_rust.so`
- `native/prebuilt/windows-x64/mongo_document_db_driver_rust.dll`

On those targets, consumers do not need Rust installed. The Dart package loads the matching library directly at runtime.

## Important Notes

- Web does not use these libraries.
- Android and iOS runtime support will require mobile-native libraries to be added here as release artifacts.
- Maintainers are responsible for refreshing this directory as part of the release process.

## Maintainer Commands

Build and stage supported desktop targets:

```bash
dart run tool/build_rust_prebuilt.dart --target=macos-arm64 --target=linux-x64 --target=windows-x64
```

Stage a library built elsewhere:

```bash
dart run tool/stage_rust_prebuilt.dart --abi=linux-x64 --source=/path/to/libmongo_document_db_driver_rust.so
```
