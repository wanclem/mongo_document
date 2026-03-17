#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake is required" >&2
  exit 1
fi

if ! command -v pkg-config >/dev/null 2>&1; then
  echo "pkg-config is required" >&2
  exit 1
fi

build_dir="native/build"
cmake -S native -B "$build_dir" -DCMAKE_BUILD_TYPE=Release
cmake --build "$build_dir" --config Release

abi_dir="$(dart tool/current_abi_dir.dart)"

out_dir="lib/src/native/$abi_dir"
mkdir -p "$out_dir"

if [[ "$OSTYPE" == "darwin"* ]]; then
  cp "$build_dir/libmongo_document_db_mongoc.dylib" "$out_dir/"
elif [[ "$OSTYPE" == "linux"* ]]; then
  cp "$build_dir/libmongo_document_db_mongoc.so" "$out_dir/"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32"* ]]; then
  cp "$build_dir/Release/mongo_document_db_mongoc.dll" "$out_dir/" || \
    cp "$build_dir/mongo_document_db_mongoc.dll" "$out_dir/"
else
  echo "Unsupported OSTYPE: $OSTYPE" >&2
  exit 1
fi

echo "Copied native library to $out_dir"
