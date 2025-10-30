const std = @import("std");
const cli = @import("cli.zig");

const ReadErros = error{ ReadFailed, TaskTooLong, EmptyTask };

/// get task from user and returns the slice
pub fn getTask(r: *std.Io.Reader) ReadErros![]u8 {
    const task_maybe: ?[]u8 = r.takeDelimiter('\n') catch |err| switch (err) {
        error.StreamTooLong => return ReadErros.TaskTooLong,
        error.ReadFailed => return ReadErros.ReadFailed,
    };

    if (task_maybe.?.len == 0) return error.EmptyTask;
    return task_maybe.?;
}
