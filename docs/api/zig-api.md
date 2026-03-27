# Zig API Reference

Auto-generated from Zig source files in [`src/`](https://github.com/Jesssullivan/zig-keychain/tree/main/src).

These are the internal Zig modules. For C/Swift interop, see the [C FFI Reference](c-ffi.md).

### `keychain.zig`

Platform-independent keychain result.
```zig
pub const Result = union(enum) {
```

Store a generic secret in the platform keychain.
```zig
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
```

Look up a generic secret from the platform keychain.
```zig
pub fn lookup(service: []const u8, account: []const u8) !Result {
```

Delete a generic secret from the platform keychain.
```zig
pub fn delete(service: []const u8, account: []const u8) !void {
```

Search for keychain items matching an account name.
Writes matching service names as null-separated strings into `out_buf`.
Returns the number of matches found.
```zig
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
```


### `keychain_linux.zig`

```zig
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
```

```zig
pub fn lookup(service: []const u8, account: []const u8) !keychain.Result {
```

```zig
pub fn delete(service: []const u8, account: []const u8) !void {
```

Search for keychain items matching an account name.
Writes matching service names as null-separated strings into `out_buf`.
Returns the number of matches found, or an error.
```zig
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
```


### `keychain_macos.zig`

Store a generic password via SecItemAdd.
```zig
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
```

Look up a generic password via SecItemCopyMatching.
```zig
pub fn lookup(service: []const u8, account: []const u8) !keychain.Result {
```

Delete a generic password via SecItemDelete.
```zig
pub fn delete(service: []const u8, account: []const u8) !void {
```

Search for keychain items matching an account name.
Writes matching service names as null-separated strings into `out_buf`.
Returns the number of matches found, or an error.
```zig
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
```

