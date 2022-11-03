const std = @import("std");
const Pkg = std.build.Pkg;
const FileSource = std.build.FileSource;

pub const pkgs = struct {
    pub const clap = Pkg{
        .name = "clap",
        .source = FileSource{
            .path = ".gyro\\clap-Hejsil-0.6.0-astrolabe.pm\\pkg\\clap.zig",
        },
    };

    pub fn addAllTo(artifact: *std.build.LibExeObjStep) void {
        artifact.addPackage(pkgs.clap);
    }
};
