const cons = @import("constants");
const clap = @import("clap");
const std = @import("std");

const debug = std.debug;
const io = std.io;
const fs = std.fs;
const process = std.process;
const allocator = std.heap.page_allocator;

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                        Display this help and exit.
        \\-p, --path            <str>...    the file or dir path you want to change eol.
        \\-t, --type            <str>...    LF or CRLF
        \\-x, --extension       <str>...    file extension, example: zig
        \\-h, --hidden_enable               available to change hidden dir and file
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
    var hidenEnable: bool = false;

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
                return cons.ZEolError.WrongEolTypeError;
            }
        } else {
            debug.print("type is empty", .{});
        }
        if (res.args.extension.len > 0) {
            extension = res.args.extension[0];
        }
        if (res.args.hidden_enable) {
            hidenEnable = true;
        }
    }
    handleFiles(fileDirPath, eolType, extension, hidenEnable) catch |err| {
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

fn handleFiles(path: []const u8, eolType: u8, extension: ?[]const u8, hidden: bool) !void {
    debug.print("path: {s}\n", .{path});
    if (!isDir(path) and extensionCheck(extension)) {
        if (extEql(path, extension)) {
            var content: []u8 = try readFile(path);
            debug.print("eolType: {any}, content length: {any}\n", .{ eolType, content.len });
            const size = checkOutputSize(eolType, content);
            debug.print("output size: {}\n", .{size});
            if (size != content.len) {
                var memory: []u8 = try allocator.alloc(u8, size);
                defer allocator.free(memory);
                try cleanEol(content, &memory);
                try writeFile(path, memory);
            }
        }
    } else {
        const iterableDir = try fs.openIterableDirAbsolute(path, cons.openDirOptions);
        var iterator = iterableDir.iterate();
        while (try iterator.next()) |entry| {
            if (std.mem.startsWith(u8, entry.name, ".") and !hidden) {
                continue;
            }
            var pathArray = [_][]const u8{ path, entry.name };
            var curPath: []u8 = try std.mem.join(allocator, "/", &pathArray);
            try handleFiles(curPath, eolType, extension, hidden);
        }
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
    var dir = fs.openDirAbsolute(path, cons.openDirOptions) catch |e| {
        debug.print("{any}\n", .{e});
        return false;
    };
    defer fs.Dir.close(&dir);
    return true;
}

fn extEql(path: []const u8, extension: ?[]const u8) bool {
    if (extension != null) {
        const ext = fs.path.extension(path);
        debug.print("{s}\n", .{ext});
        if (ext.len == 0) {
            return false;
        }
        return std.mem.eql(u8, ext[1..], extension.?);
    }
    return true;
}

fn readFile(path: []const u8) ![]u8 {
    var file: fs.File = undefined;
    {
        file = try fs.openFileAbsolute(path, cons.openFileFlags);
        defer file.close();
        var buffer: [1024 * 1024]u8 = undefined;
        var bytesRead = try file.readAll(&buffer);
        return buffer[0..bytesRead];
    }
}

fn writeFile(path: []const u8, content: []u8) !void {
    var file: fs.File = undefined;
    {
        file = try fs.createFileAbsolute(path, cons.createFileFlags);
        defer file.close();
        try file.writeAll(content);
    }
}

fn checkOutputSize(eolType: u8, content: []u8) usize {
    switch (eolType) {
        @enumToInt(cons.Eol.LF) => {
            const crlfCount = std.mem.count(u8, content, "\r\n");
            return content.len - crlfCount;
        },
        @enumToInt(cons.Eol.CRLF) => {
            const lfCount = std.mem.count(u8, content, "\n");
            return content.len + lfCount;
        },
        else => unreachable,
    }
}

fn cleanEol(content: []u8, output: *[]u8) !void {
    if (output.*.len > content.len) {
        _ = std.mem.replace(u8, content, "\n", "\r\n", output.*[0..]);
        debug.print("{s}\n", .{output.*});
    } else if (output.*.len < content.len) {
        _ = std.mem.replace(u8, content, "\r\n", "\n", output.*[0..]);
        debug.print("{s}\n", .{output.*});
    } else {
        return;
    }
}
