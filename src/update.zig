const std = @import("std");
const Allocator = std.mem.Allocator;
const Child = std.process.Child;

// url must be something like: https://github.com/nat3Github/zig-lib-dvui-dev-fork
//  branch must be something like main or dev
pub fn get_hash(alloc: Allocator, url: []const u8, branch: []const u8) ![]const u8 {
    const get_commit = &.{ "git", "ls-remote", url };
    const dat = try exec(alloc, get_commit);
    var tokenizer = std.mem.tokenizeAny(u8, dat, "\r\n");
    var hash: []const u8 = "";
    const refs_heads = "refs/heads/";
    var arlist = std.ArrayList([]const u8).init(alloc);
    defer arlist.deinit();
    while (tokenizer.next()) |token| {
        hash = token[0..40];
        var ref = std.mem.trim(u8, token[40..], " \t");
        if (std.ascii.startsWithIgnoreCase(ref, refs_heads)) ref = ref[refs_heads.len..];
        if (std.mem.eql(u8, branch, ref)) return alloc.dupe(u8, hash);
        try arlist.append(ref);
    }
    const branches = arlist.items;
    std.log.err("url: {s} BRANCH: '{s}' NOT FOUND", .{ url, branch });
    std.log.info("there are {} other branches:", .{branches.len});
    for (branches[0..@min(10, branches.len)]) |s| {
        std.log.info("{s}", .{s});
    }
    return error.BranchNotFound;
}

pub fn get_zig_fetch_repo_string(alloc: Allocator, url: []const u8, branch: []const u8) ![]const u8 {
    const hash = try get_hash(alloc, url, branch);
    const repo = try std.fmt.allocPrint(alloc, "git+{s}#{s}", .{ url, hash });
    return repo;
}

pub const GitDependency = struct {
    url: []const u8,
    branch: []const u8,
};

pub fn update_dependency(alloc: Allocator, deps: []const GitDependency) !void {
    for (deps) |dep| {
        const rep = try get_zig_fetch_repo_string(alloc, dep.url, dep.branch);
        std.log.info("running zig fetch --save {s}", .{rep});
        _ = try exec(alloc, &.{
            "zig",
            "fetch",
            "--save",
            rep,
        });
    }
    std.log.info("ok", .{});
}

pub fn exec(alloc: Allocator, args: []const []const u8) ![]const u8 {
    var caller = Child.init(args, alloc);
    caller.stdout_behavior = .Pipe;
    caller.stderr_behavior = .Pipe;
    var stdout = std.ArrayListUnmanaged(u8){};
    var stderr = std.ArrayListUnmanaged(u8){};
    errdefer stdout.deinit(alloc);
    defer stderr.deinit(alloc);
    try caller.spawn();
    try caller.collectOutput(alloc, &stdout, &stderr, 1024 * 1024);
    const res = try caller.wait();
    if (res.Exited > 0) {
        std.log.err("{s}\n", .{stderr.items});
        return error.Failed;
    } else {
        return stdout.items;
    }
}
pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();
    const Deps = std.ArrayList(GitDependency);
    var deps = Deps.init(alloc);
    defer deps.deinit();
    var it = try std.process.ArgIterator.initWithAllocator(alloc);
    _ = it.next(); // skip programm name
    while (it.next()) |s| {
        var d: GitDependency = undefined;
        d.url = s;
        d.branch = it.next() orelse return error.ParseError;
        try deps.append(d);
    }
    try update_dependency(alloc, deps.items);
}

/// the name in options will be added as build option
/// i.e. "update" -> zig build -Dupdate will trigger the update binary
/// if you want to update the Update itself with every invokation, add it to the list of GitDependencies
///
/// you have to wrap this function in a guard clause like
/// if (updateDependencies(...)) return;
/// in your build.zig file and place it at the top of you build fn!
/// Then, if you pass -Dupdate the build script will only do the updating and not error on missing dependencies in the rest of the build script!
pub fn updateDependencies(b: *std.Build, dependencies: []const GitDependency, options: std.Build.ExecutableOptions) bool {
    var opts = options;
    const dep = b.dependency("update_tool", .{
        // .optimize = opts.optimize,
        // .target = opts.target,
    });
    opts.root_source_file = dep.path("src/update.zig");
    const build_exe = b.addExecutable(opts);
    const run_step = b.addRunArtifact(build_exe);
    for (dependencies) |d| {
        run_step.addArg(d.url);
        run_step.addArg(d.branch);
    }
    run_step.step.dependOn(&build_exe.step);
    const upd = if (b.option(bool, opts.name, "breaks the build script and updates dependencies")) |x| x else false;
    if (upd) {
        b.getInstallStep().dependOn(&run_step.step);
    }
    return upd;
}
