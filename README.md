# update tool - a zig dependency update tool for your remote git dependencies
- i hate searching for the right commit hash and manually calling zig fetch --save git+...#aEfowkjdfwfd..
- this lib called `update_tool` gets the hash from the specified branch and runs zig fetch --save

# automatic test steps
- with `addTestFolder` all zig files in the specified folder get added as test steps

# Example Updating Git Dependencies
1. in build.zig.zon you add:
```zig
    .dependencies = .{
        .update_tool = .{
            .url = "git+https://github.com/nat3Github/zig-lib-update#b1383fe265ce7636b374d09b23e6ef67ee4eb46b",
            .hash = "update_tool-0.0.0-MwAI-RQUAAAyN5KtivKv0CvCYu_NLd-QRv515tb4xdQ0",
        },
        // ...
    },
```

2. in build.zig you define your dependencies:
```zig
const update = @import("update_tool");
const deps: []const update.GitDependency = &.{
    .{
        // if you leave this the update_tool will update itself 
        .url = "https://github.com/nat3Github/zig-lib-update",
        .branch = "main",
    },
    .{
        // update lib-pffft
        .url = "https://github.com/nat3Github/zig-lib-osmr",
        .branch = "zig",
    },
    // add more dependencies here
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (update.updateDependencies(b, deps, .{
        .name = "update",
        .optimize = optimize,
        .target = target,
    })) return;
```


3. run `zig build -Dupdate` to invoke the update tool

# Example Adding Tests

1. in build.zig you define your test folder:
```zig
const update = @import("update_tool");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    ...
    try update.addTestFolder(
        b,
        // this is the folder path (from build root)
        "tests",
        optimize,
        target,
        // add modules that are used in the tests
        &.{
            .{ .name = "my-module", .mod = my_module_i_want_to_test },
        },
        // this is the prefix- for the tests
        "testprefix",
    );
```
2.
```
add a new file (first-test.zig) to the test folder
run `zig build testprefix-first-test.zig` to run the tests in first-test.zig
or run `zig build testprefix-all` to run all tests of that folder
```

# Usage
this is Public Domain feel free to use it!

# Performance
- it gets slow with a lot of dependencies
- this is due to zig fetch --save being slow
- i hope this gets improved on in future zig versions
