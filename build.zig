const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/ffi.zig"),
        .target = target,
        .optimize = optimize,
    });

    const resolved_target = root_module.resolved_target.?;

    // Linux: compile C bridge for libsecret varargs + link system libs
    if (resolved_target.result.os.tag == .linux) {
        root_module.link_libc = true;
        root_module.addCSourceFile(.{
            .file = b.path("src/libsecret_bridge.c"),
            .flags = &.{ "-std=c99", "-Wall" },
        });
        // Use pkg-config to find libsecret and glib headers/libs
        // (works on Debian, Fedora, Arch, NixOS, etc.)
        root_module.linkSystemLibrary("libsecret-1", .{});
        root_module.linkSystemLibrary("glib-2.0", .{});
        // Bridge header for zig @cImport
        root_module.addIncludePath(b.path("src"));
    }

    // macOS: link Security + CoreFoundation frameworks
    if (resolved_target.result.os.tag == .macos) {
        root_module.linkFramework("Security", .{});
        root_module.linkFramework("CoreFoundation", .{});
    }

    // Zig module for package manager consumers
    _ = b.addModule("zig-keychain", .{
        .root_source_file = b.path("src/ffi.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Static library for C FFI consumers
    const lib = b.addLibrary(.{
        .name = "zig-keychain",
        .root_module = root_module,
        .linkage = .static,
    });

    b.installArtifact(lib);

    // Documentation generation
    const docs_step = b.step("docs", "Generate API documentation");
    const docs_mod = b.createModule(.{
        .root_source_file = b.path("src/ffi.zig"),
        .target = target,
        .optimize = optimize,
    });
    docs_mod.link_libc = true;
    const docs_lib = b.addLibrary(.{
        .name = "zig-keychain",
        .root_module = docs_mod,
        .linkage = .static,
    });
    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs_lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);

    // Unit tests
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
