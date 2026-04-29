## Summary

-

## Scope

- [ ] Keeps the existing C ABI stable, or documents any ABI addition in `include/zig_keychain.h`, README, and docs.
- [ ] Keeps C FFI exports in `src/ffi.zig`.
- [ ] Keeps Zig package exports routed through `src/root.zig`.
- [ ] Keeps generic-password keychain scope clear: no claims of SwiftUI, AppKit, UIKit, Cocoa, iCloud Keychain, Secure Enclave, LocalAuthentication, access groups, synchronizable items, certificates, or private-key identity replacement.
- [ ] Updates docs or examples when public behavior changes.

## Validation

- [ ] `zig build test`
- [ ] `zig build docs`
- [ ] `zig build example`
- [ ] `zig build -Doptimize=ReleaseFast`

## Notes

Link related issues and call out any platform-specific caveats.
