const clap = @import("clap");
const std = @import("std");

const debug = std.debug;
const io = std.io;
const process = std.process;
const fs = std.fs;

const EoL = enum([]const u8) {
    LF = "\n",
    CRLF = "\r\n",
};

const Task = struct {
    path: []const u8,
    eol_type: EoL,
};

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                Display this help and exit.
        \\-p, --path    <str>...    the file or dir path you want to change eol.
        \\-t, --type    <str>...    LF or CRLF
        \\<str>...
        \\
    );
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    var fileDirPath: []const u8 = undefined;
    var eolType: []const u8 = undefined;

    if (res.args.help) {
        showHelpMessage();
    } else {
        if (res.args.path.len > 0) {
            fileDirPath = res.args.path[0];
        } else {
            debug.print("path is empty", .{});
        }
        if (res.args.type.len > 0) {
            eolType = res.args.type[0];
        } else {
            debug.print("type is empty", .{});
        }
    }
}

fn showHelpMessage() void {
    const helpMessage =
        \\-h, --help             Display this help and exit.
        \\-p, --path    <str>    source file or dir path, example --path "D:\zig\README.md"
        \\-t, --type    <str>    target eol type, example: eoler --type LR
    ;
    debug.print("Help Message: \n{s}\n", .{helpMessage});
}

fn fileOrDir(path: []const u8) bool {}

fn readFileAndChange() void {}
