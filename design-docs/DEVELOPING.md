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
in-browser we can target `wasm64-unknown-unknown` (the WebAssembly `memory64`
proposal). This is a Rust tier-3 target, so it requires nightly Rust and
`-Z build-std`, plus a small patch to `getrandom` (vendored under `vendor/`)
because upstream gates its `wasm_js` backend on `target_arch = "wasm32"`.

Prerequisites:

```
rustup install nightly
rustup +nightly component add rust-src
cargo install wasm-bindgen-cli --version 0.2.121 --locked
```

Build the wasm64 GUI artifacts:

```
./scripts/build-wasm64.sh        # produces dist/wasm64/{app,worker}_bg.wasm + JS glue
```

Browser support: `memory64` ships unflagged in current Chrome, Firefox and
Safari. The Tauri desktop wrapper inherits the system WebView's support.

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
