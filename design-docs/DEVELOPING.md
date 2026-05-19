## Local UI (browser)

Start by installing `trunk` with:

```
cargo install trunk
```

Use the following command to build and open the UI in a browser:

```
cd smt-scope-gui && trunk serve --cargo-profile=test --open
```

## Local UI (native)

Install `trunk` as described above, then install `tauri` with:

```
cargo install tauri-cli
```

Use the following command to build and open the UI in a native window:

```
cargo tauri dev
```

## Local UI (browser, wasm64 / >2 GiB traces)

The default browser build targets `wasm32-unknown-unknown`, whose linear memory
is `u32`-indexed and so caps trace parsing at ~2 GiB. To process larger traces
we can target `wasm64-unknown-unknown` (the WebAssembly `memory64` proposal).
This is a Rust tier-3 target, so it requires nightly Rust and `-Z build-std`,
plus a small patch to `getrandom` (vendored under `vendor/`) because upstream
gates its `wasm_js` backend on `target_arch = "wasm32"`.

Engine support: as of May 2026, `memory64` ships unflagged in **Firefox** and
**Chromium-based browsers** (Chrome, Edge). WebKit/JavaScriptCore has not yet
shipped it, so this build does **not** run in Safari, in iOS browsers, or in
any Tauri webview (Tauri uses WKWebView on macOS and webkit2gtk on Linux).

Prerequisites:

```
rustup install nightly
rustup +nightly component add rust-src
cargo install wasm-bindgen-cli --version 0.2.121 --locked
```

Build the wasm64 static site:

```
./scripts/build-wasm64.sh
```

This produces `dist/wasm64/` containing `index.html`, the wasm-bindgen JS
glue, the wasm modules, and the copied static assets. Serve it locally and
open in Firefox or Chrome:

```
python3 -m http.server -d dist/wasm64 8000
# then open http://localhost:8000/
```

To sanity-check whether a given browser supports memory64, open
`scripts/memory64-probe.html` in it.

## Profiling

Use the following command to profile the program:

```
cargo flamegraph --root --profile=test --bin=smt-scope -- test /path/to/z3.log
```

## Running tests

Run the `parse_logs` test with the following command (or just run `cargo test -- --nocapture`):

```
cargo test --package smt-scope --test parse_logs -- parse_all_logs --exact --show-output --nocapture
```
