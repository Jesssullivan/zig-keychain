const keychain = @import("keychain.zig");

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
