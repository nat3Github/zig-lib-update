# update tool - a zig dependency update tool for your remote git dependencies
- i hate searching for the right commit hash and manually calling zig fetch --save git+...#aEfowkjdfwfd..
- this is why i created this lib called update_tool
- it gets the right hash from the specified branch and runs zig fetch --save

# Example
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
