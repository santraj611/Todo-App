const std = @import("std");
const builtin = @import("builtin");
const cli = @import("cli.zig");
const todo = @import("todo.zig");
const cmd = @import("commands.zig");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const native_os = builtin.target.os.tag;
    const gpa, const is_debug = gpa: {
        if (native_os == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    // writer
    var writer_buffer: [1024]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&writer_buffer);
    const w = &stdout.interface;

    // reader
    var reader_buff: [1024]u8 = undefined;
    var stdin = std.fs.File.stdin().reader(&reader_buff);
    const r = &stdin.interface;

    // iter over args
    for (args) |arg| {
        // std.debug.print("#{d}. {s}\n", .{ i, arg });
        if (std.mem.eql(u8, arg, "add")) {
            const b_read: usize = try cmd.getTask(r, w);

            // debuging
            std.debug.print("Reader Buffer: {s}\n", .{reader_buff});
            std.debug.print("Writer Buffer: {s}\n", .{writer_buffer});

            try w.print("{d} bytes read\n", .{b_read});
            try w.print("Task: {s}\n", .{reader_buff[0..b_read]});
            try w.flush();

            // debuging
            std.debug.print("Reader Buffer: {s}\n", .{reader_buff});
            std.debug.print("Writer Buffer: {s}\n", .{writer_buffer});
        }
    }
}
