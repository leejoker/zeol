const std = @import("std");
const fs = std.fs;

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
