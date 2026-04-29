# Apple Interop

zig-keychain is a portable generic-secret FFI, not an Apple application framework. It is useful when an application needs a small credential storage capability that can move between Apple platforms and Linux without keeping separate Keychain Services and Secret Service call sites.

## Apple Analogs

The closest Apple surfaces are:

- `SecItemAdd` for generic-password storage
- `SecItemCopyMatching` for lookup and attribute search
- `SecItemDelete` for deletion
- `kSecClassGenericPassword`, `kSecAttrService`, `kSecAttrAccount`, and `kSecValueData`
- Swift or Objective-C bridging headers for C ABI calls

The current macOS backend links Security.framework and CoreFoundation.framework. It stores generic-password data by service/account. It does not expose access-control prompts, keychain sharing groups, synchronizable/iCloud items, certificates, identities, private keys, or Secure Enclave flows.

## Available Now

- C ABI callable from Swift, Objective-C, C, C++, and other FFI hosts
- `zig_keychain_store` for generic-password storage
- `zig_keychain_lookup` for service/account lookup
- `zig_keychain_delete` for deletion
- `zig_keychain_search` for account-based service discovery
- Binary secret payloads through explicit length parameters
- Linux Secret Service/libsecret backend for matching store/lookup/delete/search workflows
- Direct Zig package API through `src/root.zig`

## Not Yet Available

- SwiftPM package, module map, or XCFramework packaging
- Objective-C sample app and nullability annotations
- Dedicated Swift wrapper types around the C ABI
- Keychain Services and libsecret migration examples
- Access-control policies, biometric prompts, access groups, synchronizable/iCloud items, certificates, identities, private-key APIs, or Secure Enclave support
- A Linux backend that documents and tests multiple Secret Service providers

## Contributor Starting Points

Good first issues should stay small and should make one missing interop path easier to verify. Useful starting points include a SwiftPM/modulemap smoke test, an Objective-C bridge sample, C header nullability annotations, and a migration table from Keychain Services concepts to the current zig-keychain surface.
