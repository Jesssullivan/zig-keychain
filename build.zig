const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const resolved_target = target.result;
    const is_linux = resolved_target.os.tag == .linux;

    // Static library for C FFI
    const lib = b.addLibrary(.{
        .name = "zig-keychain",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/ffi.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });

    // Link libsecret on Linux (needed for @cImport of libsecret/secret.h)
    if (is_linux) {
        lib.root_module.linkSystemLibrary("libsecret-1", .{});
        lib.root_module.linkSystemLibrary("glib-2.0", .{});
    }

    b.installArtifact(lib);

    // Unit tests (platform-conditional)
    const test_step = b.step("test", "Run unit tests");

    const t = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/keychain.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    if (is_linux) {
        t.root_module.linkSystemLibrary("libsecret-1", .{});
        t.root_module.linkSystemLibrary("glib-2.0", .{});
    }

    test_step.dependOn(&b.addRunArtifact(t).step);
}
