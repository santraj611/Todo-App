const std = @import("std");
const cli = @import("cli.zig");

/// get task from user and returns the bytes read
pub fn getTask(r: *std.Io.Reader, w: *std.Io.Writer) !usize {
    try w.print("What would you like to Add in your TODO list?\n", .{});
    try w.flush();
    @memset(w.buffer, 0);
    const b_read: usize = try r.streamDelimiter(w, '\n');
    return b_read;
}
