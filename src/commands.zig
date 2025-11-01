const std = @import("std");
const cli = @import("cli.zig");

const ReadErros = error{ ReadFailed, TaskTooLong, NoInput, OutOfMemory };

/// get task from user and returns the slice
pub fn getTask(alloc: std.mem.Allocator, r: *std.Io.Reader) ReadErros![]u8 {
    const line: ?[]u8 = r.takeDelimiter('\n') catch |err| switch (err) {
        error.StreamTooLong => return ReadErros.TaskTooLong,
        error.ReadFailed => return ReadErros.ReadFailed,
    };

    // takeDelimiter returns ?[]u8
    const slice = line orelse return ReadErros.NoInput;

    // make a copy that caller owns
    return try alloc.dupe(u8, slice);
}
