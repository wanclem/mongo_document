# mongo_document_db_driver Rust Core

This crate is the native backend for `mongo_document_db_driver`.

It wraps MongoDB's official Rust driver and exposes a stable C ABI that the Dart package calls through FFI.

## What Lives Here

- the dependency on MongoDB's officially maintained Rust driver crate
- the native client open/close/ping entrypoints
- BSON command and CRUD execution
- cursor open / `getMore` / close support
- Rust-side logging and native error reporting

The public Dart API stays in the Dart package. The actual MongoDB runtime behavior on supported native targets lives here.

## Build

```bash
cargo build --manifest-path packages/mongo_document_db_driver/native/rust/Cargo.toml --release
```

This build step is for maintainers only.
Consumers of the Dart package should not need Rust installed locally.

## Produce or Refresh Prebuilt Libraries

The normal maintainer flow is:

```bash
dart run tool/build_rust_prebuilt.dart --target=macos-arm64 --target=linux-x64 --target=windows-x64
```

Or, if you already built a library elsewhere:

```bash
dart run tool/stage_rust_prebuilt.dart --abi=linux-x64 --source=/path/to/libmongo_document_db_driver_rust.so
```

## Versioning

The Rust dependency graph is controlled by:

- `Cargo.toml`
- `Cargo.lock`

That means the shipped native libraries are built against the exact locked Rust driver version in this crate, not whatever happens to be latest at install time.
