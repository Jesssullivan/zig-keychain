const std = @import("std");
const builtin = @import("builtin");
const keychain = @import("keychain.zig");

// Linux: libsecret via thin C bridge (src/libsecret_bridge.c)
// The bridge handles C varargs calls to libsecret which zig cannot invoke directly.
// Requires: libsecret-1-dev (Ubuntu) or libsecret-devel (Rocky/Fedora)

const bridge = if (builtin.os.tag == .linux) @cImport({
    @cInclude("libsecret_bridge.h");
}) else struct {};

pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
    if (builtin.os.tag != .linux) return error.UnsupportedPlatform;

    var svc_buf: [256]u8 = undefined;
    var acc_buf: [256]u8 = undefined;
    if (service.len >= svc_buf.len or account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(svc_buf[0..service.len], service);
    svc_buf[service.len] = 0;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    const result = bridge.libsecret_bridge_store(&svc_buf, &acc_buf, data.ptr, data.len);
    if (result != 0) return error.StoreFailed;
}

pub fn lookup(service: []const u8, account: []const u8, out_buf: []u8) !keychain.Result {
    if (builtin.os.tag != .linux) return error.UnsupportedPlatform;

    var svc_buf: [256]u8 = undefined;
    var acc_buf: [256]u8 = undefined;
    if (service.len >= svc_buf.len or account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(svc_buf[0..service.len], service);
    svc_buf[service.len] = 0;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    const result = bridge.libsecret_bridge_lookup(&svc_buf, &acc_buf, out_buf.ptr, out_buf.len);
    if (result == -1) return .not_found;
    if (result < 0) return .{ .err = "libsecret lookup failed" };
    return .{ .success = out_buf[0..@intCast(result)] };
}

pub fn delete(service: []const u8, account: []const u8) !void {
    if (builtin.os.tag != .linux) return error.UnsupportedPlatform;

    var svc_buf: [256]u8 = undefined;
    var acc_buf: [256]u8 = undefined;
    if (service.len >= svc_buf.len or account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(svc_buf[0..service.len], service);
    svc_buf[service.len] = 0;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    const result = bridge.libsecret_bridge_delete(&svc_buf, &acc_buf);
    if (result != 0) return error.DeleteFailed;
}

pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
    if (builtin.os.tag != .linux) return error.UnsupportedPlatform;

    var acc_buf: [256]u8 = undefined;
    if (account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    const result = bridge.libsecret_bridge_search(&acc_buf, @ptrCast(out_buf), out_capacity);
    if (result < 0) return error.SearchFailed;
    return @intCast(result);
}
