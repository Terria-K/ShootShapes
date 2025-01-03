const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    const ziglangSet = b.dependency("ziglangSet", .{
        .target = target,
        .optimize = optimize
    });


    const atlas_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("assets/result.zig")
    });

    const build_options = b.addOptions();

    const exe = b.addExecutable(.{
        .name = "ShootShapes",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const sourceFiles = &[_][]const u8{"./lib/src/zig_includes.c"};
    const sourceFlags = &[_][]const u8{ "-g", "-O3" };

    exe.addCSourceFiles(.{ .files = sourceFiles, .flags = sourceFlags });
    exe.addLibraryPath(b.path("bin/lib64"));
    exe.addIncludePath(b.path("lib/include"));
    exe.addIncludePath(b.path("lib/SDL3/include"));
    if (target.result.isMinGW()) {
        exe.addObjectFile(b.path("bin/x64/SDL3.dll"));
        build_options.addOption(bool, "is_windows", true);
    } else if (target.result.isDarwin()) {
        exe.addObjectFile(b.path("bin/osx/libSDL2-2.0.0.dylib"));
        build_options.addOption(bool, "is_windows", false);
    } else {
        exe.linkSystemLibrary("SDL3");
        exe.linkSystemLibrary("FAudio");
        build_options.addOption(bool, "is_windows", false);
    }

    const mod = build_options.createModule();
    exe.root_module.addImport("atlas", atlas_mod);
    exe.root_module.addImport("checks", mod);
    exe.root_module.addImport("ziglangSet", ziglangSet.module("ziglangSet"));
    exe.linkLibC();

    

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_tests.addCSourceFiles(.{ .files = sourceFiles, .flags = sourceFlags });
    main_tests.addIncludePath(b.path("lib/include"));
    main_tests.linkLibC();

    main_tests.root_module.addImport("ziglangSet", ziglangSet.module("ziglangSet"));

    const run_main_tests = b.addRunArtifact(main_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_main_tests.step);
}