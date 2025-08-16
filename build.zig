const std = @import("std");
pub const update = @import("update.zig");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = .{ target, optimize };
    // if (update.updateDependencies(b, xdeps, .{
    //     .name = "update",
    //     .optimize = optimize,
    //     .target = target,
    // })) return;
}

test "test all refs" {
    std.testing.refAllDeclsRecursive(@This());
}
