# Source Tree: zig-keychain

```
zig-keychain/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── docs.yml
├── docs/
│   ├── api/
│   │   ├── c-ffi.md  (C FFI Reference)
│   │   └── zig-api.md  (Zig API Reference)
│   ├── guides/
│   │   ├── building.md  (Building)
│   │   └── integration.md  (Integration Guide)
│   ├── agents.md  (AGENTS.md)
│   ├── index.md  (zig-keychain)
│   ├── llms.txt
│   └── source-tree.md  (Source Tree: zig-keychain)
├── include/
│   └── zig_keychain.h  (C header -- 4 functions)
├── scripts/
│   ├── gen_api_docs.py
│   └── gen_docs.py
├── src/
│   ├── ffi.zig  (C FFI exports)
│   ├── keychain.zig  (Platform keychain abstraction)
│   ├── keychain_linux.zig  (Linux libsecret backend)
│   └── keychain_macos.zig  (macOS Security.framework backend)
├── .coderabbit.yaml
├── .envrc
├── .gitignore
├── AGENTS.md  (zig-keychain -- Agent Interface)
├── LICENSE  (License)
├── LLMS.txt
├── README.md  (zig-keychain)
├── build.zig
├── flake.nix  (Nix flake)
└── mkdocs.yml  (MkDocs configuration)
```
