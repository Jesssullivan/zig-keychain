# AGENTS.md -- zig-keychain

## Capabilities

- System keychain/credential storage (store, lookup, delete)

## C FFI Exports (zig_keychain.h)

| Function | Return | Description |
|----------|--------|-------------|
| `zig_keychain_store` | `int` | Store a generic password in the system keychain/secret store. macOS: SecItemAdd (kSecClassGenericPassword) Linux: libsecret secret_service_store_sync (org.freedesktop.secrets) |
| `zig_keychain_lookup` | `int` | Look up a generic password from the system keychain/secret store. macOS: SecItemCopyMatching (kSecClassGenericPassword, kSecReturnData) Linux: libsecret secret_service_lookup_sync |
| `zig_keychain_delete` | `int` | Delete a generic password from the system keychain/secret store. macOS: SecItemDelete Linux: libsecret secret_service_clear_sync |
| `zig_keychain_search` | `int` | Search for keychain items matching an account prefix. Writes matching service names as null-separated strings. macOS: SecItemCopyMatching (kSecMatchLimitAll, kSecReturnAttributes) Linux: libsecret secret_service_search_sync |

## Error Conventions

- Return `0` on success
- Return `-1` on failure
- Functions returning data length return byte count on success, negative on error

## Platform Requirements

**macOS:**
- Frameworks: CoreFoundation, Security
- Targets: arm64, x86_64

**Linux:**
- Libraries: libsecret-1
- Targets: arm64, x86_64

## Build

```bash
zig build                              # static library -> zig-out/lib/
zig build -Doptimize=ReleaseFast       # optimized build
zig build test                         # unit tests
```

## Linking

The library builds as a static archive. Include the header
from `include/` and link `zig-out/lib/libzig-keychain.a`.

At final link time, the consuming application must link platform frameworks/libraries.
The static library intentionally does not link them to support cross-compilation.

