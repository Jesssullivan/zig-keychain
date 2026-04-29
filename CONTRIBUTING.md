# Contributing to zig-keychain

## Installation

### Zig Package Manager (recommended)

```bash
zig fetch --save git+https://github.com/Jesssullivan/zig-keychain.git
```

Then in your `build.zig`:

```zig
const dep = b.dependency("zig_keychain", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("zig-keychain", dep.module("zig-keychain"));
```

### Git Submodule (C FFI consumers)

```bash
git submodule add https://github.com/Jesssullivan/zig-keychain.git vendor/keychain
cd vendor/keychain && zig build -Doptimize=ReleaseFast
```

Link (macOS): `-lzig-keychain -framework Security -framework CoreFoundation`

Link (Linux): `-lzig-keychain $(pkg-config --libs libsecret-1 glib-2.0)`

Include `#include "zig_keychain.h"`.

## Development

### Prerequisites

- Zig 0.15.2+
- **macOS:** Security.framework and CoreFoundation.framework (included with Xcode/CLT)
- **Linux:** `libsecret-1-dev` and `libglib2.0-dev` (Debian/Ubuntu) or `libsecret-devel` and `glib2-devel` (Fedora/RHEL)

### Build & Test

```bash
zig build                        # static library
zig build -Doptimize=ReleaseFast # optimized build
zig build test                   # unit tests
zig build docs                   # generate API documentation
zig build example                # build C example
```

## Where to Start

Start with issues labeled [`good first issue`](https://github.com/Jesssullivan/zig-keychain/labels/good%20first%20issue) or [`help wanted`](https://github.com/Jesssullivan/zig-keychain/labels/help%20wanted).

Small, useful first contributions include:

- SwiftPM/modulemap smoke tests
- Objective-C bridging samples
- C header nullability annotations
- Swift wrapper examples
- Keychain Services and libsecret migration documentation

### Code Style

- `zig fmt` for formatting
- All `pub` and `export` functions need `///` doc comments
- C FFI exports go in `src/ffi.zig`
- Zig package exports go through `src/root.zig`
- Platform backends in `src/keychain_<platform>.zig`
- Platform dispatch in `src/keychain.zig`

### Adding a new operation

1. Add the Zig function to `src/keychain.zig` with platform dispatch
2. Implement in `src/keychain_macos.zig` and `src/keychain_linux.zig`
3. Add `export fn zig_keychain_<name>` wrapper in `src/ffi.zig`
4. Add the C declaration to `include/zig_keychain.h`
5. Update `AGENTS.md` FFI table and `llms-full.txt`

## Filing Issues

Open an issue at [github.com/Jesssullivan/zig-keychain/issues](https://github.com/Jesssullivan/zig-keychain/issues).

## License

Dual-licensed under [Zlib](https://opensource.org/licenses/Zlib) and [MIT](https://opensource.org/licenses/MIT).
