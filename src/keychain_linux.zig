const std = @import("std");
const keychain = @import("keychain.zig");

// Linux: libsecret via D-Bus (Secret Service API)
// This requires libsecret-1 to be installed.
// On Rocky Linux: dnf install libsecret-devel
// On Ubuntu: apt install libsecret-1-dev

const c = @cImport({
    @cInclude("libsecret/secret.h");
});

const schema = c.SecretSchema{
    .name = "com.cmuxterm.secrets",
    .flags = c.SECRET_SCHEMA_NONE,
    .attributes = .{
        .{ .name = "service", .type = c.SECRET_SCHEMA_ATTRIBUTE_STRING },
        .{ .name = "account", .type = c.SECRET_SCHEMA_ATTRIBUTE_STRING },
        .{ .name = null, .type = 0 },
    },
};

pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
    // Null-terminate strings for C API
    var svc_buf: [256]u8 = undefined;
    var acc_buf: [256]u8 = undefined;
    if (service.len >= svc_buf.len or account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(svc_buf[0..service.len], service);
    svc_buf[service.len] = 0;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    var err: ?*c.GError = null;
    const ok = c.secret_password_store_binary_sync(
        &schema,
        c.SECRET_COLLECTION_DEFAULT,
        &svc_buf,
        c.SecretValue.new(@ptrCast(data.ptr), @intCast(data.len), "application/octet-stream"),
        null,
        &err,
        "service",
        &svc_buf,
        "account",
        &acc_buf,
        @as(?*anyopaque, null),
    );
    if (!ok) {
        if (err) |e| c.g_error_free(e);
        return error.LibsecretStoreFailed;
    }
}

pub fn lookup(service: []const u8, account: []const u8) !keychain.Result {
    var svc_buf: [256]u8 = undefined;
    var acc_buf: [256]u8 = undefined;
    if (service.len >= svc_buf.len or account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(svc_buf[0..service.len], service);
    svc_buf[service.len] = 0;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    var err: ?*c.GError = null;
    const value = c.secret_password_lookup_binary_sync(
        &schema,
        null,
        &err,
        "service",
        &svc_buf,
        "account",
        &acc_buf,
        @as(?*anyopaque, null),
    );
    if (value == null) {
        if (err) |e| {
            c.g_error_free(e);
            return .{ .err = "libsecret lookup failed" };
        }
        return .not_found;
    }
    defer c.secret_value_unref(value.?);
    var len: c.gsize = 0;
    const ptr = c.secret_value_get(value.?, &len);
    return .{ .success = ptr[0..len] };
}

pub fn delete(service: []const u8, account: []const u8) !void {
    var svc_buf: [256]u8 = undefined;
    var acc_buf: [256]u8 = undefined;
    if (service.len >= svc_buf.len or account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(svc_buf[0..service.len], service);
    svc_buf[service.len] = 0;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    var err: ?*c.GError = null;
    _ = c.secret_password_clear_sync(
        &schema,
        null,
        &err,
        "service",
        &svc_buf,
        "account",
        &acc_buf,
        @as(?*anyopaque, null),
    );
    if (err) |e| {
        c.g_error_free(e);
        return error.LibsecretDeleteFailed;
    }
}
