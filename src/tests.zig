const std = @import("std");
const Mod = struct {
    name: []const u8,
    mod: *std.Build.Module,
};

/// adds all files in test folder as step in the build script under step-name-file-name
/// run all tests with step-name-all
pub fn addTestFolder(b: *std.Build, test_folder_sub_path: []const u8, optimize: anytype, target: anytype, modules: []const Mod, step_name: []const u8) !void {
    const all_tests_step = b.step(b.fmt("{s}-all", .{step_name}), b.fmt("run all tests of {s}", .{step_name}));

    const test_dir = b.path(test_folder_sub_path);
    var dir = try b.build_root.handle.openDir(test_folder_sub_path, .{
        .iterate = true,
    });
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |e| {
        if (e.kind == .file) {
            const mod = b.createModule(.{
                .root_source_file = test_dir.path(b, e.name),
                .optimize = optimize,
                .target = target,
            });
            for (modules) |m| {
                mod.addImport(m.name, m.mod);
            }
            const exe = b.addExecutable(.{
                .root_module = mod,
                .name = b.fmt("{s}", .{e.name}),
            });
            const exe_run = b.addRunArtifact(exe);
            const test_ = b.addTest(.{
                .root_module = mod,
            });
            const run_ = b.addRunArtifact(test_);
            const step = b.step(b.fmt("{s}-{s}", .{ step_name, e.name }), b.fmt("run test for {s}", .{e.name}));
            step.dependOn(&run_.step);
            step.dependOn(&exe_run.step);
            all_tests_step.dependOn(step);
        }
    }
}
