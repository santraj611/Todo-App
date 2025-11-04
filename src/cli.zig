const std = @import("std");

const ReadError = error{ ReadFailed, TaskTooLong, NoInput, OutOfMemory };

/// get task from user and returns the slice.
pub fn getTask(alloc: std.mem.Allocator, r: *std.Io.Reader) ReadError![]u8 {
    const line: ?[]u8 = r.takeDelimiter('\n') catch |err| switch (err) {
        error.StreamTooLong => return ReadError.TaskTooLong,
        error.ReadFailed => return ReadError.ReadFailed,
    };

    // takeDelimiter returns ?[]u8
    const slice = line orelse return ReadError.NoInput;

    // make a copy that caller owns
    return try alloc.dupe(u8, slice);
}
