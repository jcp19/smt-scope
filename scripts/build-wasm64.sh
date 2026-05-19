#!/usr/bin/env bash
# Build smt-scope-gui for wasm64-unknown-unknown (memory64), bypassing the
# ~2 GiB ceiling of the default wasm32 build. See design-docs/DEVELOPING.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=wasm64-unknown-unknown
PROFILE=${PROFILE:-release}
OUT="$ROOT/dist/wasm64"

cd "$ROOT/smt-scope-gui"

for bin in app worker; do
    rustup run nightly cargo build \
        --target "$TARGET" \
        -Z build-std=std,panic_abort \
        --bin "$bin" \
        --profile "$PROFILE"
done

mkdir -p "$OUT"
for bin in app worker; do
    wasm-bindgen \
        --target web \
        --out-dir "$OUT" \
        "$ROOT/target/$TARGET/$PROFILE/$bin.wasm"
done

echo "wasm64 artifacts in $OUT"
