# Building

## Requirements

- Zig 0.15.2+
- macOS 13+ (Security.framework) or Linux (libsecret-1-dev)

## Static Library

```bash
zig build -Doptimize=ReleaseFast
```

Produces `zig-out/lib/libzig-keychain.a` with the C header at `include/zig_keychain.h`.

## With Nix

```bash
nix develop        # dev shell with Zig 0.15.2
```

## Running Tests

```bash
zig build test
```

!!! note
    Tests that access the real system keychain may require user interaction (macOS Keychain access dialog) or a running D-Bus session (Linux).

## Platform Dependencies

**macOS**: Links against `Security.framework` and `CoreFoundation.framework` at final link time.

**Linux**: Requires `libsecret-1-dev` (Debian/Ubuntu) or `libsecret-devel` (Fedora):

```bash
# Debian/Ubuntu
sudo apt install libsecret-1-dev

# Fedora
sudo dnf install libsecret-devel
```

Linux runtime delivery also requires a Secret Service provider and D-Bus session, such as GNOME Keyring or KWallet through a compatible service.
