const keychain = @import("keychain.zig");

/// Store a generic secret in the system keychain (macOS SecItem) or secret
/// store (Linux libsecret). Uses upsert semantics: an existing item with the
/// same service+account pair is replaced.
///
/// Returns 0 on success, -1 on failure.
export fn zig_keychain_store(
    service: [*]const u8,
    service_len: usize,
    account: [*]const u8,
    account_len: usize,
    data: [*]const u8,
    data_len: usize,
) c_int {
    keychain.store(
        service[0..service_len],
        account[0..account_len],
        data[0..data_len],
    ) catch return -1;
    return 0;
}

/// Look up a generic secret from the system keychain/secret store by
/// service name and account name. Copies the secret data into the
/// caller-provided output buffer.
///
/// Returns the number of bytes written on success, -1 if the item was
/// not found, or -2 on error (including buffer too small).
export fn zig_keychain_lookup(
    service: [*]const u8,
    service_len: usize,
    account: [*]const u8,
    account_len: usize,
    out: [*]u8,
    out_capacity: usize,
) c_int {
    const result = keychain.lookup(
        service[0..service_len],
        account[0..account_len],
    ) catch return -2;

    switch (result) {
        .success => |data| {
            if (data.len > out_capacity) return -2;
            @memcpy(out[0..data.len], data);
            return @intCast(data.len);
        },
        .not_found => return -1,
        .err => return -2,
    }
}

/// Delete a generic secret from the system keychain/secret store,
/// matched by service name and account name.
///
/// Returns 0 on success (including when the item does not exist),
/// -1 on error.
export fn zig_keychain_delete(
    service: [*]const u8,
    service_len: usize,
    account: [*]const u8,
    account_len: usize,
) c_int {
    keychain.delete(
        service[0..service_len],
        account[0..account_len],
    ) catch return -1;
    return 0;
}

/// Search for keychain items whose account name matches the given value.
/// Writes matching service names as null-separated strings into the
/// caller-provided output buffer.
///
/// Returns the number of matches found, or -1 on error.
export fn zig_keychain_search(
    account: [*]const u8,
    account_len: usize,
    out: [*]u8,
    out_capacity: usize,
) c_int {
    const count = keychain.search(
        account[0..account_len],
        out,
        out_capacity,
    ) catch return -1;
    return @intCast(count);
}
