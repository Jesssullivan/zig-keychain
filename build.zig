const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ffi_module = b.createModule(.{
        .root_source_file = b.path("src/ffi.zig"),
        .target = target,
        .optimize = optimize,
    });
    addPlatformDeps(ffi_module, target, b, true);

    // Zig module for package manager consumers.
    const zig_module = b.addModule("zig-keychain", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    addPlatformDeps(zig_module, target, b, true);

    // Static library for C FFI consumers.
    const lib = b.addLibrary(.{
        .name = "zig-keychain",
        .root_module = ffi_module,
        .linkage = .static,
    });

    b.installArtifact(lib);

    // Documentation generation.
    const docs_step = b.step("docs", "Generate API documentation");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);

    // C example. Build only: running it writes to the real keychain.
    const example_step = b.step("example", "Build the C example");
    const example_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    example_module.link_libc = true;
    example_module.addIncludePath(b.path("include"));
    example_module.addCSourceFile(.{
        .file = b.path("examples/store_lookup.c"),
        .flags = &.{ "-std=c99", "-Wall", "-Wextra" },
    });
    example_module.linkLibrary(lib);
    addPlatformDeps(example_module, target, b, false);

    const example = b.addExecutable(.{
        .name = "store_lookup",
        .root_module = example_module,
    });
    example_step.dependOn(&example.step);

    // Unit tests
    const test_step = b.step("test", "Run unit tests");
    inline for (.{
        "src/root.zig",
        "src/keychain.zig",
    }) |test_file| {
        const test_module = b.createModule(.{
            .root_source_file = b.path(test_file),
            .target = target,
            .optimize = optimize,
        });
        addPlatformDeps(test_module, target, b, true);
        const t = b.addTest(.{
            .root_module = test_module,
        });
        test_step.dependOn(&b.addRunArtifact(t).step);
    }
}

fn addPlatformDeps(module: *std.Build.Module, target: std.Build.ResolvedTarget, b: *std.Build, include_bridge: bool) void {
    switch (target.result.os.tag) {
        .linux => {
            module.link_libc = true;
            if (include_bridge) {
                module.addCSourceFile(.{
                    .file = b.path("src/libsecret_bridge.c"),
                    .flags = &.{ "-std=c99", "-Wall", "-Wextra" },
                });
            }
            module.linkSystemLibrary("libsecret-1", .{});
            module.linkSystemLibrary("glib-2.0", .{});
            module.linkSystemLibrary("gobject-2.0", .{});
            module.addIncludePath(b.path("src"));
        },
        .macos => {
            module.linkFramework("Security", .{});
            module.linkFramework("CoreFoundation", .{});
        },
        else => {},
    }
}
