const std = @import("std");
const builtin = @import("builtin");

/// Platform-independent keychain lookup result.
///
/// On success, the returned slice aliases the caller-provided output buffer
/// passed to `lookup`.
pub const Result = union(enum) {
    success: []const u8,
    not_found,
    err: []const u8,
};

/// Store a generic secret in the platform keychain.
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
    if (builtin.os.tag == .macos) {
        return @import("keychain_macos.zig").store(service, account, data);
    } else if (builtin.os.tag == .linux) {
        return @import("keychain_linux.zig").store(service, account, data);
    } else {
        return error.UnsupportedPlatform;
    }
}

/// Look up a generic secret from the platform keychain.
pub fn lookup(service: []const u8, account: []const u8, out_buf: []u8) !Result {
    if (builtin.os.tag == .macos) {
        return @import("keychain_macos.zig").lookup(service, account, out_buf);
    } else if (builtin.os.tag == .linux) {
        return @import("keychain_linux.zig").lookup(service, account, out_buf);
    } else {
        return error.UnsupportedPlatform;
    }
}

/// Delete a generic secret from the platform keychain.
pub fn delete(service: []const u8, account: []const u8) !void {
    if (builtin.os.tag == .macos) {
        return @import("keychain_macos.zig").delete(service, account);
    } else if (builtin.os.tag == .linux) {
        return @import("keychain_linux.zig").delete(service, account);
    } else {
        return error.UnsupportedPlatform;
    }
}

/// Search for keychain items matching an account name.
/// Writes matching service names as null-separated strings into `out_buf`.
/// Returns the number of matches found.
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
    if (builtin.os.tag == .macos) {
        return @import("keychain_macos.zig").search(account, out_buf, out_capacity);
    } else if (builtin.os.tag == .linux) {
        return @import("keychain_linux.zig").search(account, out_buf, out_capacity);
    } else {
        return error.UnsupportedPlatform;
    }
}
