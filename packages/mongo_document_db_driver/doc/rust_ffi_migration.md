# Rust FFI Migration

## Goal

Replace the current pure-Dart socket/protocol engine with a Rust `cdylib`
backed by MongoDB's official Rust driver, while preserving the existing Dart
consumer API (`Db`, `DbCollection`, generated CRUD helpers, and
`MongoDbConnection`).

## Why

The current failure mode is not just one bug. The foundational problem is that
we own too much of the wire protocol, topology management, retries, and pooling
inside Dart. That keeps putting us back into connection-state and replica-set
edge cases that official drivers have already solved.

## Public API Strategy

The external API stays stable:

- `Db`
- `DbCollection`
- `ModernCursor`
- generated CRUD APIs from `mongo_document`
- `MongoDbConnection`

The migration happens underneath those APIs by introducing a native backend and
keeping the Dart surface as a facade.

## Distribution Strategy

Consumers should not need Rust installed locally.

That means the release line cannot depend on compiling the Rust crate from
source on every user machine. Instead:

1. Maintainers build release native libraries in CI and during package release.
2. The resulting `.so` / `.dylib` / `.dll` files are shipped inside the package
   under `native/prebuilt/<os>-<arch>/`.
3. A package build hook bundles the correct library automatically for the
   target platform when Dart builds or runs an application that depends on this
   package.
4. The Dart API stays unchanged and does not expose Rust-specific setup to
   package consumers.

## Query Builder Strategy

`mongo_dart_query` should not survive as a core dependency of the new backend.
It is mostly a query-construction DSL, not the actual transport/runtime layer.

Long-term direction:

1. Keep generated method signatures stable.
2. Replace `SelectorBuilder` / `ModifierBuilder` dependence with an internal
   query AST and `Map<String, Object?>` compiler.
3. Let generated code emit plain filter/update maps directly where possible.

This keeps consumers stable while removing a dependency that is tightly coupled
to the old driver architecture.

## Phases

### Phase 1

- Introduce Rust `cdylib` scaffold.
- Introduce Dart FFI loader, ABI binding seam, and prebuilt native asset hook.
- Keep current Dart driver active by default.

### Phase 2

- Implement native open/close/ping/findOne/find/findMany/aggregate/insert/update/delete.
- Add BSON/JSON bridge conventions across Dart and Rust.
- Route selected `DbCollection` operations through the Rust backend.

### Phase 3

- Implement cursor streaming and change streams.
- Add stable error mapping from Rust driver errors to Dart exceptions.
- Add backend selection + rollout guard.

### Phase 4

- Remove `mongo_dart_query` from generated/runtime hot paths.
- Remove old pure-Dart socket engine once parity is proven.

## Non-Goals

- No sidecar processes.
- No consumer-facing package split.
- No breaking changes to generated CRUD method names/signatures unless
  unavoidable.
