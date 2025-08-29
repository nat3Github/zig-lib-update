const std = @import("std");
pub const update = @import("src/update.zig");
const tests = @import("src/tests.zig");
pub const GitDependency = update.GitDependency;
pub const updateDependencies = update.updateDependencies;
pub const addTestFolder = tests.add_tests;

pub fn build(_: *std.Build) void {}

test "test all refs" {
    std.testing.refAllDeclsRecursive(@This());
}
