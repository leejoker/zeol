const std = @import("std");

const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const test_all_step = b.step("test", "Run all tests in all modes.");
    for ([_]bool{ true, false }) |stage1| {
        for (std.meta.tags(std.builtin.Mode)) |test_mode| {
            const mode_str = @tagName(test_mode);
            const stage1_str = if (stage1) "stage1" else "stage2";

            const tests = b.addTest("clap.zig");
            tests.setBuildMode(test_mode);
            tests.setTarget(target);
            tests.use_stage1 = stage1;

            const test_step = b.step(
                b.fmt("test-{s}-{s}", .{ stage1_str, mode_str }),
                b.fmt("Run all tests with {s} compiler in {s}.", .{ stage1_str, mode_str }),
            );
            test_step.dependOn(&tests.step);
            test_all_step.dependOn(test_step);
        }
    }

    const example_step = b.step("examples", "Build examples");
    inline for (.{
        "simple",
        "simple-ex",
        //"simple-error",
        "streaming-clap",
        "help",
        "usage",
    }) |example_name| {
        const example = b.addExecutable(example_name, "example/" ++ example_name ++ ".zig");
        example.addPackagePath("clap", "clap.zig");
        example.setBuildMode(mode);
        example.setTarget(target);
        example.install();
        example_step.dependOn(&example.step);
    }

    const readme_step = b.step("readme", "Remake README.");
    const readme = readMeStep(b);
    readme.dependOn(example_step);
    readme_step.dependOn(readme);

    const all_step = b.step("all", "Build everything and runs all tests");
    all_step.dependOn(test_all_step);
    all_step.dependOn(example_step);
    all_step.dependOn(readme_step);

    b.default_step.dependOn(all_step);
}

fn readMeStep(b: *Builder) *std.build.Step {
    const s = b.allocator.create(std.build.Step) catch unreachable;
    s.* = std.build.Step.init(.custom, "ReadMeStep", b.allocator, struct {
        fn make(step: *std.build.Step) anyerror!void {
            @setEvalBranchQuota(10000);
            _ = step;
            const file = try std.fs.cwd().createFile("README.md", .{});
            const stream = file.writer();
            try stream.print(@embedFile("example/README.md.template"), .{
                @embedFile("example/simple.zig"),
                @embedFile("example/simple-ex.zig"),
                @embedFile("example/streaming-clap.zig"),
                @embedFile("example/help.zig"),
                @embedFile("example/usage.zig"),
            });
        }
    }.make);
    return s;
}
