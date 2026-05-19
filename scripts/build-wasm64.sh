#!/usr/bin/env bash
# Build smt-scope-gui as a static wasm64 site (memory64), bypassing the ~2 GiB
# ceiling of the default wasm32 build. Output is a fully servable directory
# that loads in any browser supporting memory64 (Firefox, Chromium).
#
# Tauri/WebKit-based browsers (Safari, webkit2gtk) do not yet implement
# memory64, so the dist produced here will not run inside Tauri's webview.
#
# See design-docs/DEVELOPING.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=wasm64-unknown-unknown
PROFILE=${PROFILE:-release}
OUT="${OUT:-$ROOT/dist/wasm64}"

cd "$ROOT/smt-scope-gui"

for bin in app worker; do
    # `tauri` here means "self-hosted build" — it disables the ChannelSelect
    # version widget, which calls chrono::Utc::now() and panics on wasm64
    # because chrono's wasmbind backend is `cfg(target_arch = "wasm32")` only.
    rustup run nightly cargo build \
        --target "$TARGET" \
        -Z build-std=std,panic_abort \
        --bin "$bin" \
        --features tauri \
        --profile "$PROFILE"
done

rm -rf "$OUT"
mkdir -p "$OUT"

# App: ES module entry, loaded via <script type="module">.
wasm-bindgen --target web --out-dir "$OUT" \
    "$ROOT/target/$TARGET/$PROFILE/app.wasm"

# Worker: classic-script entry (yew-agent uses `new Worker("worker.js")` with no
# {type: "module"}), so we emit --target no-modules and append a self-init line.
wasm-bindgen --target no-modules --out-dir "$OUT" \
    "$ROOT/target/$TARGET/$PROFILE/worker.wasm"
cat >> "$OUT/worker.js" <<'EOF'

// Auto-initialise when loaded as a Web Worker via `new Worker("worker.js")`.
if (typeof WorkerGlobalScope !== "undefined" && self instanceof WorkerGlobalScope) {
    wasm_bindgen("./worker_bg.wasm").catch((e) => console.error("worker init failed:", e));
}
EOF

# Static assets — mirror the trunk index.html's `copy-dir` of assets/html.
cp -R "$ROOT/smt-scope-gui/assets/html" "$OUT/html"

# Entry HTML. Mirrors smt-scope-gui/index.html but replaces the trunk-managed
# `<link data-trunk rel="rust" ...>` tags with a direct ES-module import.
cat > "$OUT/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0" />
    <title>SMTScope</title>
    <link rel="icon" type="image/x-icon" href="html/favicon.ico">
    <link rel="stylesheet" href="html/style.css">
    <link rel="stylesheet" href="html/perfetto.css">
    <link href="https://fonts.googleapis.com/css?family=Roboto:300,400,500" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Roboto+Condensed:300,400,500" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Material+Icons|Material+Icons+Outlined&display=block" rel="stylesheet">
</head>
<body>
    <script type="module">
        // wasm-bindgen's --target web `init()` only runs the externref-table
        // setup via `__wbindgen_start`; for a Rust `bin` crate we still have
        // to invoke `main()` ourselves. Trunk does this implicitly; we don't.
        // `main` is exported with the C signature `int main(int argc, char**
        // argv)` — on wasm64 `argv` is `i64`, so we must pass a BigInt instead
        // of letting `undefined` slide through (which would have worked on
        // wasm32 with `i32`).
        import init from "./app.js";
        init()
            .then((wasm) => { wasm.main(0, 0n); })
            .catch((err) => {
                console.error("smt-scope init failed:", err);
                const parts = [
                    "smt-scope failed to start.",
                    "",
                    "name:    " + (err && err.name),
                    "message: " + (err && err.message),
                    "string:  " + String(err),
                    "type:    " + typeof err,
                    "ctor:    " + (err && err.constructor && err.constructor.name),
                    "",
                    "stack:",
                    (err && err.stack) || "(none)",
                ];
                document.body.innerHTML =
                    "<pre style='color:#b00020;white-space:pre-wrap;padding:1rem;font:13px/1.4 ui-monospace,monospace'>"
                    + parts.join("\n").replace(/[&<>]/g, (c) => ({"&":"&amp;","<":"&lt;",">":"&gt;"})[c])
                    + "</pre>";
            });
    </script>
</body>
</html>
EOF

echo
echo "Built wasm64 static site in $OUT"
echo "Serve with:   python3 -m http.server -d $OUT 8000"
echo "Then open:    http://localhost:8000/  (in Firefox or Chrome)"
