# Source Tree: zig-keychain

```
zig-keychain/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   ├── config.yml
│   │   ├── documentation.yml
│   │   └── feature_request.yml
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── docs.yml
│   │   └── release.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   ├── api/
│   │   ├── c-ffi.md  (C FFI API Reference: zig-keychain)
│   │   └── zig-api.md  (Zig API Reference: zig-keychain)
│   ├── guides/
│   │   ├── apple-interop.md  (Apple Interop)
│   │   ├── building.md  (Building)
│   │   └── integration.md  (Integration Guide)
│   ├── agents.md  (AGENTS.md)
│   ├── index.md  (zig-keychain)
│   ├── llms.txt
│   └── source-tree.md  (Source Tree: zig-keychain)
├── examples/
│   └── store_lookup.c
├── include/
│   └── zig_keychain.h  (C header -- 4 functions)
├── scripts/
│   ├── gen_api_docs.py
│   └── gen_docs.py
├── src/
│   ├── ffi.zig  (C FFI exports)
│   ├── keychain.zig  (Platform keychain abstraction)
│   ├── keychain_linux.zig  (Linux libsecret backend)
│   ├── keychain_macos.zig  (macOS Security.framework backend)
│   ├── libsecret_bridge.c
│   ├── libsecret_bridge.h  (C header -- 4 functions)
│   └── root.zig  (Public Zig package API for zig-keychain.)
├── .coderabbit.yaml
├── .envrc
├── .gitignore
├── AGENTS.md  (AGENTS.md -- zig-keychain)
├── CONTRIBUTING.md  (Contributing to zig-keychain)
├── LICENSE  (License)
├── README.md  (zig-keychain)
├── SECURITY.md  (Security Policy)
├── build.zig
├── build.zig.zon
├── flake.nix  (Nix flake)
├── llms-full.txt
├── llms.txt
└── mkdocs.yml  (MkDocs configuration)
```
