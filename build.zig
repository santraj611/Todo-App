const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const mod = b.addModule("todo_app", .{
    //     // The root source file is the "entry point" of this module. Users of
    //     // this module will only be able to access public declarations contained
    //     // in this file, which means that if you have declarations that you
    //     // intend to expose to consumers that were defined in other files part
    //     // of this module, you will have to make sure to re-export them from
    //     // the root file.
    //     .root_source_file = b.path("src/root.zig"),
    //     // Later on we'll use this module as the root module of a test executable
    //     // which requires us to specify a target.
    //     .target = target,
    // });

    const exe = b.addExecutable(.{
        .name = "todo_app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            // List of modules available for import in source files part of the
            // root module.
            // .imports = &.{
            //     // Here "todo_app" is the name you will use in your source code to
            //     // import this module (e.g. `@import("todo_app")`). The name is
            //     // repeated because you are allowed to rename your imports, which
            //     // can be extremely useful in case of collisions (which can happen
            //     // importing modules from different packages).
            //     .{ .name = "todo_app", .module = mod },
            // },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    // By making the run step depend on the default step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }


    // Creates an executable that will run `test` blocks from the executable's
    // root module. Note that test executables only test one module at a time,
    // hence why we have to create two separate ones.
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    // A run step that will run the second test executable.
    const run_exe_tests = b.addRunArtifact(exe_tests);

    // A top level step for running all tests. dependOn can be called multiple
    // times and since the two run steps do not depend on one another, this will
    // make the two of them run in parallel.
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
