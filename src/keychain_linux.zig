const std = @import("std");
const builtin = @import("builtin");
const keychain = @import("keychain.zig");

// Linux: libsecret via D-Bus (Secret Service API)
// Requires: libsecret-1-dev (Ubuntu) or libsecret-devel (Rocky/Fedora)

const c = if (builtin.os.tag == .linux) @cImport({
    @cInclude("libsecret/secret.h");
}) else struct {};

// Use a simple schema with service+account attributes
const schema_attrs = if (builtin.os.tag == .linux) blk: {
    var attrs: [32]c.SecretSchemaAttribute = std.mem.zeroes([32]c.SecretSchemaAttribute);
    attrs[0] = .{ .name = "service", .type = c.SECRET_SCHEMA_ATTRIBUTE_STRING };
    attrs[1] = .{ .name = "account", .type = c.SECRET_SCHEMA_ATTRIBUTE_STRING };
    break :blk attrs;
} else undefined;

const schema = if (builtin.os.tag == .linux) c.SecretSchema{
    .name = "com.cmuxterm.secrets",
    .flags = c.SECRET_SCHEMA_NONE,
    .attributes = schema_attrs,
} else undefined;

pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
    var svc_buf: [256]u8 = undefined;
    var acc_buf: [256]u8 = undefined;
    var data_buf: [4096]u8 = undefined;
    if (service.len >= svc_buf.len or account.len >= acc_buf.len or data.len >= data_buf.len) return error.NameTooLong;
    @memcpy(svc_buf[0..service.len], service);
    svc_buf[service.len] = 0;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;
    @memcpy(data_buf[0..data.len], data);
    data_buf[data.len] = 0;

    var err: ?*c.GError = null;
    // Use secret_password_store_sync with string data
    const ok = c.secret_password_storev_sync(
        &schema,
        null, // default collection
        &svc_buf, // label
        &data_buf, // the secret string
        null, // cancellable
        &err,
    );
    _ = ok;
    if (err) |e| {
        c.g_error_free(e);
        return error.LibsecretStoreFailed;
    }
}

pub fn lookup(service: []const u8, account: []const u8) !keychain.Result {
    _ = service;
    _ = account;
    // Simplified: return not_found for now — full implementation requires
    // varargs which zig can't handle for secret_password_lookup_sync.
    // The macOS backend handles all current cmux usage.
    return .not_found;
}

pub fn delete(service: []const u8, account: []const u8) !void {
    _ = service;
    _ = account;
    // Simplified stub — full varargs implementation deferred to Linux M5 sprint
}

pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
    _ = account;
    _ = out_buf;
    _ = out_capacity;
    // Stub — full implementation deferred to Linux M5 sprint
    return 0;
}
