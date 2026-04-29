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
exe.root_module.addImport("zig-keychain", keychain_dep.module("zig-keychain"));
```

For C ABI consumers, build this repository as a static library and link `zig-out/lib/libzig-keychain.a`.

## As a C Static Library

Build and link against `libzig-keychain.a`:

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

This repository does not yet ship a SwiftPM package or module map. Use a bridging header that includes `include/zig_keychain.h`, add the header search path, and link the static library.

```swift
import Foundation

let service = "myapp"
let account = "user@example.com"
let secret = Array("my-token-value".utf8)

var serviceCString = Array(service.utf8CString)
var accountCString = Array(account.utf8CString)

secret.withUnsafeBufferPointer { secretBuffer in
    serviceCString.withUnsafeBufferPointer { serviceBuffer in
        accountCString.withUnsafeBufferPointer { accountBuffer in
            _ = zig_keychain_store(
                serviceBuffer.baseAddress,
                service.utf8.count,
                accountBuffer.baseAddress,
                account.utf8.count,
                secretBuffer.baseAddress,
                secret.count
            )
        }
    }
}

var buf = [UInt8](repeating: 0, count: 1024)
serviceCString.withUnsafeBufferPointer { serviceBuffer in
    accountCString.withUnsafeBufferPointer { accountBuffer in
        buf.withUnsafeMutableBufferPointer { outBuffer in
            let len = zig_keychain_lookup(
                serviceBuffer.baseAddress,
                service.utf8.count,
                accountBuffer.baseAddress,
                account.utf8.count,
                outBuffer.baseAddress,
                outBuffer.count
            )
            if len > 0 {
                let value = String(bytes: buf[0..<Int(len)], encoding: .utf8)
                print("Found: \(value ?? "")")
            }
        }
    }
}
```

## Use Case: Browser Cookie Decryption

zig-keychain can retrieve browser encryption keys stored in the system keychain (e.g., Chrome Safe Storage), which combined with zig-crypto's PBKDF2 and AES-CBC provides cookie decryption without shelling out to the `security` CLI.
