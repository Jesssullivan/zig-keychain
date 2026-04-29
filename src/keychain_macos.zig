const std = @import("std");
const builtin = @import("builtin");
const keychain = @import("keychain.zig");

// Security.framework C bindings (only resolved on macOS)
const c = if (builtin.os.tag == .macos) @cImport({
    @cInclude("Security/Security.h");
    @cInclude("CoreFoundation/CoreFoundation.h");
}) else struct {};

/// Store a generic password via SecItemAdd.
pub fn store(service: []const u8, account: []const u8, data: []const u8) !void {
    const cf_service = cfString(service) orelse return error.CFStringCreateFailed;
    defer c.CFRelease(cf_service);
    const cf_account = cfString(account) orelse return error.CFStringCreateFailed;
    defer c.CFRelease(cf_account);
    const cf_data = c.CFDataCreate(null, data.ptr, @intCast(data.len)) orelse return error.CFDataCreateFailed;
    defer c.CFRelease(cf_data);

    // Delete existing item first (upsert pattern)
    var del_query: [3]c.CFTypeRef = undefined;
    var del_keys: [3]c.CFTypeRef = undefined;
    del_keys[0] = @ptrCast(c.kSecClass);
    del_query[0] = @ptrCast(c.kSecClassGenericPassword);
    del_keys[1] = @ptrCast(c.kSecAttrService);
    del_query[1] = cf_service;
    del_keys[2] = @ptrCast(c.kSecAttrAccount);
    del_query[2] = cf_account;
    const del_dict = c.CFDictionaryCreate(null, &del_keys, &del_query, 3, &c.kCFTypeDictionaryKeyCallBacks, &c.kCFTypeDictionaryValueCallBacks) orelse return error.DictCreateFailed;
    defer c.CFRelease(del_dict);
    _ = c.SecItemDelete(del_dict);

    // Add new item
    var add_values: [4]c.CFTypeRef = undefined;
    var add_keys: [4]c.CFTypeRef = undefined;
    add_keys[0] = @ptrCast(c.kSecClass);
    add_values[0] = @ptrCast(c.kSecClassGenericPassword);
    add_keys[1] = @ptrCast(c.kSecAttrService);
    add_values[1] = cf_service;
    add_keys[2] = @ptrCast(c.kSecAttrAccount);
    add_values[2] = cf_account;
    add_keys[3] = @ptrCast(c.kSecValueData);
    add_values[3] = @ptrCast(cf_data);
    const add_dict = c.CFDictionaryCreate(null, &add_keys, &add_values, 4, &c.kCFTypeDictionaryKeyCallBacks, &c.kCFTypeDictionaryValueCallBacks) orelse return error.DictCreateFailed;
    defer c.CFRelease(add_dict);

    const status = c.SecItemAdd(add_dict, null);
    if (status != c.errSecSuccess) return error.SecItemAddFailed;
}

/// Look up a generic password via SecItemCopyMatching.
pub fn lookup(service: []const u8, account: []const u8, out_buf: []u8) !keychain.Result {
    const cf_service = cfString(service) orelse return error.CFStringCreateFailed;
    defer c.CFRelease(cf_service);
    const cf_account = cfString(account) orelse return error.CFStringCreateFailed;
    defer c.CFRelease(cf_account);

    var keys: [5]c.CFTypeRef = undefined;
    var values: [5]c.CFTypeRef = undefined;
    keys[0] = @ptrCast(c.kSecClass);
    values[0] = @ptrCast(c.kSecClassGenericPassword);
    keys[1] = @ptrCast(c.kSecAttrService);
    values[1] = cf_service;
    keys[2] = @ptrCast(c.kSecAttrAccount);
    values[2] = cf_account;
    keys[3] = @ptrCast(c.kSecReturnData);
    values[3] = @ptrCast(c.kCFBooleanTrue);
    keys[4] = @ptrCast(c.kSecMatchLimit);
    values[4] = @ptrCast(c.kSecMatchLimitOne);

    const dict = c.CFDictionaryCreate(null, &keys, &values, 5, &c.kCFTypeDictionaryKeyCallBacks, &c.kCFTypeDictionaryValueCallBacks) orelse return error.DictCreateFailed;
    defer c.CFRelease(dict);

    var result: c.CFTypeRef = null;
    const status = c.SecItemCopyMatching(dict, &result);

    if (status == c.errSecItemNotFound) return .not_found;
    if (status != c.errSecSuccess) return .{ .err = "SecItemCopyMatching failed" };

    defer c.CFRelease(result.?);
    const cf_data: c.CFDataRef = @ptrCast(result.?);
    const len: usize = @intCast(c.CFDataGetLength(cf_data));
    if (len > out_buf.len) return .{ .err = "output buffer too small" };
    const ptr = c.CFDataGetBytePtr(cf_data);
    @memcpy(out_buf[0..len], ptr[0..len]);
    return .{ .success = out_buf[0..len] };
}

/// Delete a generic password via SecItemDelete.
pub fn delete(service: []const u8, account: []const u8) !void {
    const cf_service = cfString(service) orelse return error.CFStringCreateFailed;
    defer c.CFRelease(cf_service);
    const cf_account = cfString(account) orelse return error.CFStringCreateFailed;
    defer c.CFRelease(cf_account);

    var keys: [3]c.CFTypeRef = undefined;
    var values: [3]c.CFTypeRef = undefined;
    keys[0] = @ptrCast(c.kSecClass);
    values[0] = @ptrCast(c.kSecClassGenericPassword);
    keys[1] = @ptrCast(c.kSecAttrService);
    values[1] = cf_service;
    keys[2] = @ptrCast(c.kSecAttrAccount);
    values[2] = cf_account;

    const dict = c.CFDictionaryCreate(null, &keys, &values, 3, &c.kCFTypeDictionaryKeyCallBacks, &c.kCFTypeDictionaryValueCallBacks) orelse return error.DictCreateFailed;
    defer c.CFRelease(dict);

    const status = c.SecItemDelete(dict);
    if (status != c.errSecSuccess and status != c.errSecItemNotFound) {
        return error.SecItemDeleteFailed;
    }
}

/// Search for keychain items matching an account name.
/// Writes matching service names as null-separated strings into `out_buf`.
/// Returns the number of matches found, or an error.
pub fn search(account: []const u8, out_buf: [*]u8, out_capacity: usize) !usize {
    const cf_account = cfString(account) orelse return error.CFStringCreateFailed;
    defer c.CFRelease(cf_account);

    // Query: match all generic passwords for this account, return attributes
    var keys: [5]c.CFTypeRef = undefined;
    var values: [5]c.CFTypeRef = undefined;
    keys[0] = @ptrCast(c.kSecClass);
    values[0] = @ptrCast(c.kSecClassGenericPassword);
    keys[1] = @ptrCast(c.kSecAttrAccount);
    values[1] = cf_account;
    keys[2] = @ptrCast(c.kSecReturnAttributes);
    values[2] = @ptrCast(c.kCFBooleanTrue);
    keys[3] = @ptrCast(c.kSecMatchLimit);
    values[3] = @ptrCast(c.kSecMatchLimitAll);
    keys[4] = @ptrCast(c.kSecReturnData);
    values[4] = @ptrCast(c.kCFBooleanFalse);

    const dict = c.CFDictionaryCreate(null, &keys, &values, 5, &c.kCFTypeDictionaryKeyCallBacks, &c.kCFTypeDictionaryValueCallBacks) orelse return error.DictCreateFailed;
    defer c.CFRelease(dict);

    var result: c.CFTypeRef = null;
    const status = c.SecItemCopyMatching(dict, &result);

    if (status == c.errSecItemNotFound) return 0;
    if (status != c.errSecSuccess) return error.SecItemCopyMatchingFailed;
    if (result == null) return 0;
    defer c.CFRelease(result.?);

    // result is a CFArray of CFDictionary items
    const array: c.CFArrayRef = @ptrCast(result.?);
    const count: usize = @intCast(c.CFArrayGetCount(array));

    var written: usize = 0;
    var matches: usize = 0;

    for (0..count) |i| {
        const item: c.CFDictionaryRef = @ptrCast(c.CFArrayGetValueAtIndex(array, @intCast(i)));
        var svc_ref: c.CFTypeRef = null;
        if (c.CFDictionaryGetValueIfPresent(item, @ptrCast(c.kSecAttrService), &svc_ref) == 0) continue;

        const svc_str: c.CFStringRef = @ptrCast(svc_ref.?);
        const svc_len: usize = @intCast(c.CFStringGetLength(svc_str));

        // Get UTF-8 representation
        var buf_range = c.CFRange{ .location = 0, .length = @intCast(svc_len) };
        var used_bytes: c.CFIndex = 0;
        _ = c.CFStringGetBytes(svc_str, buf_range, c.kCFStringEncodingUTF8, '?', 0, null, 0, &used_bytes);

        const needed: usize = @intCast(used_bytes);
        // Check if we have room: service name + null terminator
        if (written + needed + 1 > out_capacity) break;

        buf_range = c.CFRange{ .location = 0, .length = @intCast(svc_len) };
        var actual_bytes: c.CFIndex = 0;
        _ = c.CFStringGetBytes(svc_str, buf_range, c.kCFStringEncodingUTF8, '?', 0, out_buf + written, @intCast(needed), &actual_bytes);

        written += @intCast(actual_bytes);
        out_buf[written] = 0; // null separator
        written += 1;
        matches += 1;
    }

    return matches;
}

fn cfString(s: []const u8) ?c.CFStringRef {
    return c.CFStringCreateWithBytes(null, s.ptr, @intCast(s.len), c.kCFStringEncodingUTF8, 0);
}
