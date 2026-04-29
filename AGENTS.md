# AGENTS.md -- zig-keychain

## Persona

You are working on zig-keychain, a cross-platform keychain/secrets abstraction in Zig with a C FFI surface. It wraps macOS Security.framework generic-password SecItem operations and Linux libsecret (D-Bus Secret Service) behind a unified 4-function C API.

## Stack

- **Language:** Zig 0.15.2+
- **Output:** Static C library (`libzig-keychain.a`) + Zig module
- **Dependencies:** Security.framework + CoreFoundation (macOS), libsecret-1 + glib-2.0 (Linux)
- **Header:** `include/zig_keychain.h` (4 C FFI functions)
- **Tests:** Unit tests in `src/keychain.zig`
- **Docs:** MkDocs Material + Zig autodoc (`zig build docs`)

## Structure

```
src/root.zig             Zig package API root
src/ffi.zig              C FFI exports (4 functions)
src/keychain.zig         Platform dispatch
src/keychain_macos.zig   macOS Security.framework backend
src/keychain_linux.zig   Linux libsecret backend
src/libsecret_bridge.c   C bridge for libsecret varargs
src/libsecret_bridge.h   Bridge header
include/zig_keychain.h   C header
examples/                C usage examples
```

## Commands

```bash
zig build                              # static library -> zig-out/lib/
zig build -Doptimize=ReleaseFast       # optimized build
zig build test                         # unit tests
zig build docs                         # generate API documentation
zig build example                      # build C usage example
```

## Style

- Format with `zig fmt`
- All `pub` and `export` functions require `///` doc comments
- C FFI exports live exclusively in `src/ffi.zig`
- Zig package exports go through `src/root.zig`
- Platform backends in `src/keychain_<platform>.zig`, one file per OS
- Platform dispatch in `src/keychain.zig`
- Error convention: return `0` on success, `-1` on failure; data-length returns use byte count on success, negative on error

## Boundaries

- **Do not** introduce platform-specific code in `src/ffi.zig` -- all platform branching goes through `keychain.zig`
- **Do not** claim SwiftUI, AppKit, UIKit, Cocoa, iCloud Keychain, Secure Enclave, LocalAuthentication, access groups, synchronizable items, certificates, or private-key identity replacement
- **Do not** store secrets in memory longer than necessary -- copy to caller buffer and avoid caching
- **Do not** add allocator-dependent APIs to the FFI surface (all buffers are caller-provided)
- **Do** keep the library stateless and thread-safe
- **Do** ensure both macOS and Linux backends are updated for any new operation

## C FFI Exports (zig_keychain.h)

| Function | Return | Description |
|----------|--------|-------------|
| `zig_keychain_store` | `int` | Store secret (upsert). macOS: SecItemAdd. Linux: libsecret SecretValue binary store |
| `zig_keychain_lookup` | `int` | Lookup secret (bytes written, -1 not found, -2 error). macOS: SecItemCopyMatching. Linux: libsecret SecretValue binary lookup |
| `zig_keychain_delete` | `int` | Delete secret (0 success incl. not-found, -1 error). macOS: SecItemDelete. Linux: secret_password_clear_sync |
| `zig_keychain_search` | `int` | Search by account (match count, -1 error). macOS: SecItemCopyMatching (kSecMatchLimitAll). Linux: secret_service_search_sync |
