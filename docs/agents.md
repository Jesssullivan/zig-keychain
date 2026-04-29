# AGENTS.md

Instructions for AI agents working with this codebase.

## Project

zig-keychain provides portable system keychain access in Zig. It abstracts macOS Keychain generic-password operations and Linux Secret Service behind a unified C FFI.

## Build

```bash
zig build -Doptimize=ReleaseFast    # static library
zig build test                       # tests
zig build example                    # C example build
```

## Structure

- `include/zig_keychain.h` -- Public C API header
- `src/root.zig` -- Zig package API root
- `src/ffi.zig` -- C FFI export layer
- `src/keychain.zig` -- Platform dispatch (routes to macos/linux impl)
- `src/keychain_macos.zig` -- macOS backend (Security.framework SecItem API)
- `src/keychain_linux.zig` -- Linux backend (libsecret D-Bus)

## Conventions

- C exports use `snake_case` with `zig_keychain_` prefix
- Zig internals use `camelCase`
- Platform-specific code in `_macos.zig` / `_linux.zig` files
- Return values: 0 = success, negative = error
- Lookup returns byte count on success, -1 = not found, -2 = error
- This repo does not replace SwiftUI, AppKit, UIKit, Cocoa, iCloud Keychain, Secure Enclave, LocalAuthentication, access groups, synchronizable items, certificates, or private-key identity APIs
