const std = @import("std");
const keychain = @import("keychain.zig");

// Linux: libsecret via D-Bus (Secret Service API)
// This requires libsecret-1 to be installed.
// On Rocky Linux: dnf install libsecret-devel
// On Ubuntu: apt install libsecret-1-dev

const c = @cImport({
    @cInclude("libsecret/secret.h");
});

const schema = blk: {
    var s: c.SecretSchema = std.mem.zeroes(c.SecretSchema);
    s.name = "com.cmuxterm.secrets";
    s.flags = c.SECRET_SCHEMA_NONE;
    s.attributes[0] = .{ .name = "service", .type = c.SECRET_SCHEMA_ATTRIBUTE_STRING };
    s.attributes[1] = .{ .name = "account", .type = c.SECRET_SCHEMA_ATTRIBUTE_STRING };
    // attributes[2+] are zero-initialized (null terminator)
    break :blk s;
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

/// Search for keychain items matching an account name.
/// Writes matching service names as null-separated strings into `out_buf`.
/// Returns the number of matches found, or an error.
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
    var acc_buf: [256]u8 = undefined;
    if (account.len >= acc_buf.len) return error.NameTooLong;
    @memcpy(acc_buf[0..account.len], account);
    acc_buf[account.len] = 0;

    // Build a GHashTable of attributes for the search
    const attrs = c.g_hash_table_new(c.g_str_hash, c.g_str_equal) orelse return error.LibsecretSearchFailed;
    defer c.g_hash_table_destroy(attrs);
    _ = c.g_hash_table_insert(attrs, @constCast(@ptrCast("account")), @ptrCast(&acc_buf));

    var err: ?*c.GError = null;
    const items = c.secret_service_search_sync(
        null, // default service
        &schema,
        attrs,
        c.SECRET_SEARCH_ALL,
        null, // cancellable
        &err,
    );
    if (err) |e| {
        c.g_error_free(e);
        return error.LibsecretSearchFailed;
    }
    if (items == null) return 0;
    defer c.g_list_free_full(items, c.g_object_unref);

    var written: usize = 0;
    var matches: usize = 0;
    var node: ?*c.GList = items;

    while (node) |n| {
        const item: *c.SecretItem = @ptrCast(@alignCast(n.data));
        const item_attrs = c.secret_item_get_attributes(item);
        if (item_attrs) |ht| {
            defer c.g_hash_table_unref(ht);
            const svc_val: ?*c.gchar = @ptrCast(c.g_hash_table_lookup(ht, @constCast(@ptrCast("service"))));
            if (svc_val) |svc| {
                const svc_len = c.strlen(svc);
                if (written + svc_len + 1 <= out_capacity) {
                    @memcpy(out_buf[written .. written + svc_len], @as([*]const u8, @ptrCast(svc))[0..svc_len]);
                    written += svc_len;
                    out_buf[written] = 0;
                    written += 1;
                    matches += 1;
                }
            }
        }
        node = n.next;
    }

    return matches;
}
