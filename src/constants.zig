const std = @import("std");
const fs = std.fs;

pub const params =
    \\-h, --help                        Display this help and exit.
    \\-p, --path            <str>...    the file or dir path you want to change eol.
    \\-t, --type            <str>...    LF or CRLF
    \\-x, --extension       <str>...    file extension, example: zig
    \\-h, --hidden_enable               available to change hidden dir and file
    \\
;

pub const helpMessage =
    \\-h, --help                Display this help and exit.
    \\-p, --path        <str>   source file or dir path, example --path "D:\zig\README.md"
    \\-t, --type        <str>   target eol type, example: eoler --type LR
    \\-x, --extension   <str>   file extension, example: zig
    \\-h, --hidden_enable               available to change hidden dir and file
;

pub const Eol = enum(u2) {
    LF,
    CRLF,
};

pub const ZEolError = error{WrongEolTypeError};

pub const openDirOptions = fs.Dir.OpenDirOptions{ .access_sub_paths = true, .no_follow = false };

pub const openFileFlags = fs.File.OpenFlags{
    .mode = fs.File.OpenMode.read_only,
    .lock = fs.File.Lock.None,
};

pub const createFileFlags = fs.File.CreateFlags{
    .read = true,
    .truncate = true,
    .lock = fs.File.Lock.Exclusive,
};
