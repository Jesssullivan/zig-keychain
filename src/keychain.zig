const std = @import("std");
const builtin = @import("builtin");

/// Platform-independent keychain result.
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
pub fn lookup(service: []const u8, account: []const u8) !Result {
    if (builtin.os.tag == .macos) {
        return @import("keychain_macos.zig").lookup(service, account);
    } else if (builtin.os.tag == .linux) {
        return @import("keychain_linux.zig").lookup(service, account);
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
