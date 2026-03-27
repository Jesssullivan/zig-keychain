const std = @import("std");
const keychain = @import("keychain.zig");

// Security.framework C bindings
const c = @cImport({
    @cInclude("Security/Security.h");
    @cInclude("CoreFoundation/CoreFoundation.h");
});

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
pub fn lookup(service: []const u8, account: []const u8) !keychain.Result {
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
    const ptr = c.CFDataGetBytePtr(cf_data);
    return .{ .success = ptr[0..len] };
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

fn cfString(s: []const u8) ?c.CFStringRef {
    return c.CFStringCreateWithBytes(null, s.ptr, @intCast(s.len), c.kCFStringEncodingUTF8, 0);
}
