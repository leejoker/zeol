const cons = @import("constants.zig");
const clap = @import("clap");
const std = @import("std");
const builtin = @import("builtin");

const debug = std.debug;
const io = std.io;
const fs = std.fs;
const process = std.process;
const os = builtin.os.tag;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(cons.params);
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    var fileDirPath: []const u8 = undefined;
    var eolType: u8 = undefined;
    var extension: ?[]const u8 = null;
    var hidenEnable: bool = false;

    if (res.args.help != 0) {
        debug.print("Help Message: \n{s}\n", .{cons.helpMessage});
        return;
    } else {
        if (res.positionals.len == 0 and res.args.path == null) {
            debug.print("path is empty.\n\n", .{});
            debug.print("Help Message: \n{s}\n", .{cons.helpMessage});
            return;
        }
        if (res.args.path != null) {
            fileDirPath = res.args.path.?;
        } else if (res.positionals.len > 0) {
            fileDirPath = res.positionals[0];
        }
        if (res.args.type != null) {
            const eolTypeStr = res.args.type.?;
            if (std.mem.eql(u8, eolTypeStr, "LF")) {
                eolType = 0;
            } else if (std.mem.eql(u8, eolTypeStr, "CRLF")) {
                eolType = 1;
            } else {
                return cons.ZEolError.WrongEolTypeError;
            }
        } else {
            var eolTypeStr: []const u8 = undefined;
            if (os == .windows) {
                eolType = 1;
                eolTypeStr = "CRLF";
            } else {
                eolType = 0;
                eolTypeStr = "LF";
            }
            debug.print("use OS eol '{s}' as default.\n", .{eolTypeStr});
        }
        if (res.args.extension != null) {
            extension = res.args.extension.?;
        }
        if (res.args.hidden_enable != 0) {
            hidenEnable = true;
        }
    }
    handleFiles(fileDirPath, eolType, extension, hidenEnable, gpa.allocator()) catch |err| {
        debug.print("Handle Files Error: {any}\n", .{err});
    };
}

fn handleFiles(path: []const u8, eolType: u8, extension: ?[]const u8, hidden: bool, allocator: std.mem.Allocator) !void {
    if (!isDir(path) and extensionCheck(extension)) {
        debug.print("handle file: {s}\n", .{path});
        if (extEql(path, extension)) {
            const content: []u8 = try readFile(path, allocator);
            defer allocator.free(content);

            debug.print("eolType: {s}, content length: {any}\n", .{ if (eolType == 0) "LF" else "CRLF", content.len });
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
        debug.print("handle dir: {s}\n", .{path});
        const iterableDir = try fs.cwd().openDir(path, cons.openDirOptions);
        var iterator = iterableDir.iterate();
        while (try iterator.next()) |entry| {
            if (std.mem.startsWith(u8, entry.name, ".") and !hidden) {
                continue;
            }
            var pathArray = [_][]const u8{ path, entry.name };
            const curPath: []u8 = try std.mem.join(allocator, "/", &pathArray);
            defer allocator.free(curPath);
            try handleFiles(curPath, eolType, extension, hidden, allocator);
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
    var dir = fs.cwd().openDir(path, cons.openDirOptions) catch |e| {
        debug.print("{any} is not a dir, run file handle\n", .{e});
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

fn readFile(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var file: fs.File = undefined;
    {
        file = try fs.cwd().openFile(path, cons.openFileFlags);
        defer file.close();
        const fileSize = try file.getEndPos();
        var buffer = try allocator.alloc(u8, fileSize);
        const bytesRead = try file.readAll(buffer);
        return buffer[0..bytesRead];
    }
}

fn writeFile(path: []const u8, content: []u8) !void {
    var file: fs.File = undefined;
    {
        file = try fs.cwd().createFile(path, cons.createFileFlags);
        defer file.close();
        try file.writeAll(content);
    }
}

fn checkOutputSize(eolType: u8, content: []u8) usize {
    switch (eolType) {
        @intFromEnum(cons.Eol.LF) => {
            const crlfCount = std.mem.count(u8, content, "\r\n");
            return content.len - crlfCount;
        },
        @intFromEnum(cons.Eol.CRLF) => {
            const lfCount = std.mem.count(u8, content, "\n");
            return content.len + lfCount;
        },
        else => unreachable,
    }
}

fn cleanEol(content: []u8, output: *[]u8) !void {
    if (output.*.len > content.len) {
        _ = std.mem.replace(u8, content, cons.LF[0..], cons.CRLF[0..], output.*[0..]);
        debug.print("{s}\n", .{output.*});
    } else if (output.*.len < content.len) {
        _ = std.mem.replace(u8, content, cons.CRLF[0..], cons.LF[0..], output.*[0..]);
        debug.print("{s}\n", .{output.*});
    } else {
        return;
    }
}
