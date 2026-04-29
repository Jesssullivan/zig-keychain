# Zig API Reference: zig-keychain

## `keychain.zig`
*Platform keychain abstraction*

### Types

#### `Result` (union)
Platform-independent keychain lookup result.  On success, the returned slice aliases the caller-provided output buffer passed to `lookup`.

### Functions

#### `store`
Store a generic secret in the platform keychain.

```zig
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void
```

#### `lookup`
Look up a generic secret from the platform keychain.

```zig
pub fn lookup(service: []const u8, account: []const u8, out_buf: []u8) !Result
```

#### `delete`
Delete a generic secret from the platform keychain.

```zig
pub fn delete(service: []const u8, account: []const u8) !void
```

#### `search`
Search for keychain items matching an account name. Writes matching service names as null-separated strings into `out_buf`. Returns the number of matches found.

```zig
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize
```

## `keychain_linux.zig`
*Linux libsecret backend*

### Functions

#### `store`

```zig
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void
```

#### `lookup`

```zig
pub fn lookup(service: []const u8, account: []const u8, out_buf: []u8) !keychain.Result
```

#### `delete`

```zig
pub fn delete(service: []const u8, account: []const u8) !void
```

#### `search`

```zig
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize
```

## `keychain_macos.zig`
*macOS Security.framework backend*

### Functions

#### `store`
Store a generic password via SecItemAdd.

```zig
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void
```

#### `lookup`
Look up a generic password via SecItemCopyMatching.

```zig
pub fn lookup(service: []const u8, account: []const u8, out_buf: []u8) !keychain.Result
```

#### `delete`
Delete a generic password via SecItemDelete.

```zig
pub fn delete(service: []const u8, account: []const u8) !void
```

#### `search`
Search for keychain items matching an account name. Writes matching service names as null-separated strings into `out_buf`. Returns the number of matches found, or an error.

```zig
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize
```

## `root.zig`
*Public Zig package API for zig-keychain.*

### Constants

- `keychain`
- `Result`
- `store`
- `lookup`
- `delete`
- `search`

