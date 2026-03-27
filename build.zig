const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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
    test_step.dependOn(&b.addRunArtifact(t).step);
}
