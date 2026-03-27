const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/ffi.zig"),
        .target = target,
        .optimize = optimize,
    });

    // On Linux, add system include paths for libsecret/glib
    const resolved_target = root_module.resolved_target.?;
    if (resolved_target.result.os.tag == .linux) {
        root_module.addSystemIncludePath(.{ .cwd_relative = "/usr/include/libsecret-1" });
        root_module.addSystemIncludePath(.{ .cwd_relative = "/usr/include/glib-2.0" });
        root_module.addSystemIncludePath(.{ .cwd_relative = "/usr/lib/x86_64-linux-gnu/glib-2.0/include" });
        root_module.addSystemIncludePath(.{ .cwd_relative = "/usr/lib/aarch64-linux-gnu/glib-2.0/include" });
    }

    // On macOS, link Security and CoreFoundation frameworks
    if (resolved_target.result.os.tag == .macos) {
        root_module.linkFramework("Security", .{});
        root_module.linkFramework("CoreFoundation", .{});
    }

    const lib = b.addLibrary(.{
        .name = "zig-keychain",
        .root_module = root_module,
        .linkage = .static,
    });

    b.installArtifact(lib);

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
