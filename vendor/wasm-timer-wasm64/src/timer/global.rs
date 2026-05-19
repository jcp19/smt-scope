pub(crate) use self::platform::*;

#[cfg(not(all(any(target_arch = "wasm32", target_arch = "wasm64"), target_os = "unknown")))]
#[path = "global/desktop.rs"]
mod platform;
#[cfg(all(any(target_arch = "wasm32", target_arch = "wasm64"), target_os = "unknown"))]
#[path = "global/wasm.rs"]
mod platform;
