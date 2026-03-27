# C FFI API Reference: zig-keychain

## `zig_keychain.h`

| Function | Description |
|----------|-------------|
| `zig_keychain_store` | Store a generic password in the system keychain/secret store. macOS: SecItemAdd (kSecClassGenericPassword) Linux: libsecret secret_service_store_sync (org.freedesktop.secrets) |
| `zig_keychain_lookup` | Look up a generic password from the system keychain/secret store. macOS: SecItemCopyMatching (kSecClassGenericPassword, kSecReturnData) Linux: libsecret secret_service_lookup_sync |
| `zig_keychain_delete` | Delete a generic password from the system keychain/secret store. macOS: SecItemDelete Linux: libsecret secret_service_clear_sync |
| `zig_keychain_search` | Search for keychain items matching an account prefix. Writes matching service names as null-separated strings. macOS: SecItemCopyMatching (kSecMatchLimitAll, kSecReturnAttributes) Linux: libsecret secret_service_search_sync |

---

### `zig_keychain_store`

Store a generic password in the system keychain/secret store. macOS: SecItemAdd (kSecClassGenericPassword) Linux: libsecret secret_service_store_sync (org.freedesktop.secrets)

```c
int zig_keychain_store( const char *service, size_t service_len, const char *account, size_t account_len, const uint8_t *data, size_t data_len );
```

**Parameters:**

- `service`: Service name (e.g., "Chrome Safe Storage").
- `service_len`: Length of service string.
- `account`: Account name.
- `account_len`: Length of account string.
- `data`: Secret data to store.
- `data_len`: Length of secret data.

**Returns:** 0 on success, -1 on failure.

### `zig_keychain_lookup`

Look up a generic password from the system keychain/secret store. macOS: SecItemCopyMatching (kSecClassGenericPassword, kSecReturnData) Linux: libsecret secret_service_lookup_sync

```c
int zig_keychain_lookup( const char *service, size_t service_len, const char *account, size_t account_len, uint8_t *out, size_t out_capacity );
```

**Parameters:**

- `service`: Service name to match.
- `service_len`: Length of service string.
- `account`: Account name to match.
- `account_len`: Length of account string.
- `out`: Output buffer for the secret data.
- `out_capacity`: Capacity of output buffer.

**Returns:** Number of bytes written on success, -1 on not found, -2 on error.

### `zig_keychain_delete`

Delete a generic password from the system keychain/secret store. macOS: SecItemDelete Linux: libsecret secret_service_clear_sync

```c
int zig_keychain_delete( const char *service, size_t service_len, const char *account, size_t account_len );
```

**Parameters:**

- `service`: Service name to match.
- `service_len`: Length of service string.
- `account`: Account name to match.
- `account_len`: Length of account string.

**Returns:** 0 on success (including not-found), -1 on error.

### `zig_keychain_search`

Search for keychain items matching an account prefix. Writes matching service names as null-separated strings. macOS: SecItemCopyMatching (kSecMatchLimitAll, kSecReturnAttributes) Linux: libsecret secret_service_search_sync

```c
int zig_keychain_search( const char *account, size_t account_len, char *out, size_t out_capacity );
```

**Parameters:**

- `account`: Account name to search for.
- `account_len`: Length of account string.
- `out`: Output buffer for null-separated service names.
- `out_capacity`: Capacity of output buffer.

**Returns:** Number of matches found, -1 on error.

