# zig-keychain -- Agent Interface

## Capabilities

- Store secrets in the system keychain (upsert semantics)
- Retrieve secrets by service + account name
- Delete secrets by service + account name
- Search keychain items by account name (header-declared, FFI pending)
- Cross-platform: macOS Security.framework and Linux libsecret

## C FFI Exports

```c
int zig_keychain_store(
    const char *service, size_t service_len,
    const char *account, size_t account_len,
    const uint8_t *data, size_t data_len
);

int zig_keychain_lookup(
    const char *service, size_t service_len,
    const char *account, size_t account_len,
    uint8_t *out, size_t out_capacity
);

int zig_keychain_delete(
    const char *service, size_t service_len,
    const char *account, size_t account_len
);

int zig_keychain_search(
    const char *account, size_t account_len,
    char *out, size_t out_capacity
);
```

## Error Codes

- **store**: `0` = success, `-1` = failure
- **lookup**: Positive = bytes written (success), `-1` = not found, `-2` = error
- **delete**: `0` = success (including not-found), `-1` = error
- **search**: Positive = match count, `-1` = error

## Thread Safety

Store, lookup, and delete are thread-safe on macOS (SecItem API is thread-safe). On Linux, libsecret sync functions are thread-safe when called from different GLib main contexts.

## Platform Requirements

**macOS:**
- Security.framework, CoreFoundation.framework (linked at final build)
- No entitlements needed for generic passwords

**Linux:**
- `apt install libsecret-1-dev` (Ubuntu/Debian) or `dnf install libsecret-devel` (Fedora/Rocky)
- glib-2.0 (dependency of libsecret)
- A running Secret Service provider (GNOME Keyring, KDE Wallet, etc.)

## Example: Complete Usage

```c
#include "zig_keychain.h"
#include <stdio.h>
#include <string.h>

int main(void) {
    const char *service = "MyApp";
    const char *account = "user@example.com";
    const char *token = "bearer-token-abc123";

    // Store
    int rc = zig_keychain_store(
        service, strlen(service),
        account, strlen(account),
        (const uint8_t*)token, strlen(token)
    );

    // Lookup
    uint8_t buf[256];
    int len = zig_keychain_lookup(
        service, strlen(service),
        account, strlen(account),
        buf, sizeof(buf)
    );
    if (len > 0) printf("Found: %.*s\n", len, buf);

    // Delete
    zig_keychain_delete(service, strlen(service), account, strlen(account));

    return 0;
}
```
