# AGENTS.md

Instructions for AI agents working with this codebase.

## Project

zig-keychain provides portable system keychain access in Zig. It abstracts macOS Keychain and Linux Secret Service behind a unified C FFI.

## Build

```bash
zig build -Doptimize=ReleaseFast    # static library
zig build test                       # tests
```

## Structure

- `include/zig_keychain.h` -- Public C API header
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
