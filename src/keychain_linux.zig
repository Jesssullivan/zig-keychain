const std = @import("std");
const builtin = @import("builtin");
const keychain = @import("keychain.zig");

// Linux: libsecret via D-Bus (Secret Service API)
// Requires: libsecret-1-dev (Ubuntu) or libsecret-devel (Rocky/Fedora)
//
// NOTE: libsecret's API uses C varargs (secret_password_store_sync, etc.)
// which zig cannot call directly. Full implementation will use a thin C
// wrapper (src/libsecret_bridge.c) during M5 Linux MVP sprint.
// The macOS backend handles all current cmux usage.

pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
    _ = .{ service, account, data };
    return error.NotImplemented;
}

pub fn lookup(service: []const u8, account: []const u8) !keychain.Result {
    _ = .{ service, account };
    return .not_found;
}

pub fn delete(service: []const u8, account: []const u8) !void {
    _ = .{ service, account };
}

pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
    _ = .{ account, out_buf, out_capacity };
    return 0;
}
