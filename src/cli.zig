const std = @import("std");

/// read user input from stdin
pub fn readInput(alloc: std.mem.Allocator, buffer: []u8) !usize {
    const stdin_buffer: []u8 = try alloc.alloc(u8, 1024);
    defer alloc.free(stdin_buffer);

    var w: std.io.Writer = .fixed(buffer);

    var stdin_reader = std.fs.File.stdin().reader(stdin_buffer);
    const stdin = &stdin_reader.interface;
    const bytes_read: usize = try stdin.streamDelimiter(&w, '\n');

    return bytes_read;
}
