const clap = @import("clap");
const std = @import("std");

const debug = std.debug;
const io = std.io;
const fs = std.fs;
const process = std.process;

const Eol = enum(u2) {
    LF,
    CRLF,
};

const ZEolError = error{WrongEolTypeError};

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                    Display this help and exit.
        \\-p, --path        <str>...    the file or dir path you want to change eol.
        \\-t, --type        <str>...    LF or CRLF
        \\-x, --extension   <str>...    file extension, example: zig
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
    var eolType: u8 = undefined;
    var extension: ?[]const u8 = null;

    if (res.args.help) {
        showHelpMessage();
    } else {
        if (res.args.path.len > 0) {
            fileDirPath = res.args.path[0];
        } else {
            debug.print("path is empty", .{});
        }
        if (res.args.type.len > 0) {
            var eolTypeStr = res.args.type[0];
            if (std.mem.eql(u8, eolTypeStr, "LF")) {
                eolType = 0;
            } else if (std.mem.eql(u8, eolTypeStr, "CRLF")) {
                eolType = 1;
            } else {
                return ZEolError.WrongEolTypeError;
            }
        } else {
            debug.print("type is empty", .{});
        }
        if (res.args.extension.len > 0) {
            extension = res.args.extension[0];
        }
    }
    handleFiles(fileDirPath, eolType, extension) catch |err| {
        debug.print("{any}\n", .{err});
    };
}

fn showHelpMessage() void {
    const helpMessage =
        \\-h, --help                Display this help and exit.
        \\-p, --path        <str>   source file or dir path, example --path "D:\zig\README.md"
        \\-t, --type        <str>   target eol type, example: eoler --type LR
        \\-x, --extension   <str>   file extension, example: zig
    ;
    debug.print("Help Message: \n{s}\n", .{helpMessage});
}

fn handleFiles(path: []const u8, eolType: u8, extension: ?[]const u8) !void {
    if (!isDir(path) and extensionCheck(extension)) {
        if (extEql(path, extension)) {
            var content: []u8 = try readFile(path);
            content = cleanEol(eolType, content);
            try writeFile(path, content);
        }
    } else {
        debug.print("Do nothing", .{});
    }
}

fn extensionCheck(extension: ?[]const u8) bool {
    if (extension == null) {
        return true;
    } else if (extension != null and extension.?.len > 0) {
        return true;
    } else {
        return false;
    }
}

fn isDir(path: []const u8) bool {
    const options = fs.Dir.OpenDirOptions{ .access_sub_paths = true, .no_follow = false };
    var dir = fs.openDirAbsolute(path, options) catch |e| {
        debug.print("{any}\n", .{e});
        return false;
    };
    defer fs.Dir.close(&dir);
    return true;
}

fn extEql(path: []const u8, extension: ?[]const u8) bool {
    if (extension != null) {
        const ext = fs.path.extension(path);
        return std.mem.eql(u8, ext[1..], extension.?);
    }
    return true;
}

fn readFile(path: []const u8) ![]u8 {
    const fileOptions = fs.File.OpenFlags{
        .mode = fs.File.OpenMode.read_only,
        .lock = fs.File.Lock.None,
    };
    var file: fs.File = undefined;
    {
        file = try fs.openFileAbsolute(path, fileOptions);
        defer file.close();
        var buffer: [1024 * 1024]u8 = undefined;
        var bytesRead = try file.readAll(&buffer);
        return buffer[0..bytesRead];
    }
}

fn writeFile(path: []const u8, content: []u8) !void {
    const fileOptions = fs.File.OpenFlags{
        .mode = fs.File.OpenMode.read_write,
        .lock = fs.File.Lock.Exclusive,
    };
    var file: fs.File = undefined;
    {
        file = try fs.openFileAbsolute(path, fileOptions);
        defer file.close();
        try file.writeAll(content);
    }
}

fn cleanEol(eolType: u8, content: []u8) []u8 {
    var output: []u8 = undefined;
    switch (eolType) {
        @enumToInt(Eol.LF) => {
            if (std.mem.count(u8, content, "\r\n") > 0) {
                _ = std.mem.replace(u8, content, "\r\n", "\n", output[0..]);
                return output;
            }
        },
        @enumToInt(Eol.CRLF) => {
            if (std.mem.count(u8, content, "\n") > 0) {
                _ = std.mem.replace(u8, content, "\n", "\r\n", output[0..]);
                return output;
            }
        },
        else => unreachable,
    }
    return content;
}
