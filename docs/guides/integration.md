# Integration Guide

## As a Zig Dependency

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .zig_keychain = .{
        .url = "https://github.com/Jesssullivan/zig-keychain/archive/refs/heads/main.tar.gz",
    },
},
```

Then in `build.zig`:

```zig
const keychain_dep = b.dependency("zig_keychain", .{
    .target = target,
    .optimize = optimize,
});
exe.linkLibrary(keychain_dep.artifact("zig_keychain"));
```

## As a C Static Library

Build and link against `libzig_keychain.a`:

```c
#include "zig_keychain.h"
#include <stdio.h>
#include <string.h>

int main() {
    const char *service = "myapp";
    const char *account = "user@example.com";
    const char *data = "my-token-value";

    // Store
    int rc = zig_keychain_store(
        service, strlen(service),
        account, strlen(account),
        (const uint8_t *)data, strlen(data)
    );

    // Lookup
    uint8_t buf[1024];
    int len = zig_keychain_lookup(
        service, strlen(service),
        account, strlen(account),
        buf, sizeof(buf)
    );
    if (len > 0) {
        printf("Found: %.*s\n", len, buf);
    }

    return 0;
}
```

## Swift Integration

```swift
import Foundation

let service = "myapp"
let account = "user@example.com"

// Lookup
var buf = [UInt8](repeating: 0, count: 1024)
let len = zig_keychain_lookup(
    service, service.utf8.count,
    account, account.utf8.count,
    &buf, buf.count
)
if len > 0 {
    let value = String(bytes: buf[0..<Int(len)], encoding: .utf8)
    print("Found: \(value ?? "")")
}
```

## Use Case: Browser Cookie Decryption

zig-keychain can retrieve browser encryption keys stored in the system keychain (e.g., Chrome Safe Storage), which combined with zig-crypto's PBKDF2 and AES-CBC provides cookie decryption without shelling out to the `security` CLI.
