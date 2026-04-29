//! Public Zig package API for zig-keychain.
//!
//! C ABI consumers should include `include/zig_keychain.h` and link the static
//! library. Zig package consumers import this module and call the same
//! platform-dispatched keychain functions directly.

pub const keychain = @import("keychain.zig");

pub const Result = keychain.Result;
pub const store = keychain.store;
pub const lookup = keychain.lookup;
pub const delete = keychain.delete;
pub const search = keychain.search;

test {
    _ = Result.not_found;
    _ = store;
    _ = lookup;
    _ = delete;
    _ = search;
}
