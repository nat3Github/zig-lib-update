const std = @import("std");
pub const update = @import("src/update.zig");
pub const GitDependency = update.GitDependency;
pub const updateDependencies = update.updateDependencies;

pub fn build(_: *std.Build) void {}

test "test all refs" {
    std.testing.refAllDeclsRecursive(@This());
}
